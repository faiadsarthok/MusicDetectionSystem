%% ============ RECORD + MATCH AGAINST DATABASE ============
recordDuration = 5;
Fs = 48000;

recObj = audiorecorder(Fs, 16, 1);

fprintf('Get ready...\n');
pause(1);

beep;
record(recObj);
fprintf('>>> RECORDING NOW <<<\n');

for t = recordDuration:-1:1
    fprintf('   %d seconds left...\n', t);
    pause(1);
end

stop(recObj);
beep;
fprintf('>>> RECORDING STOPPED <<<\n');

y = getaudiodata(recObj);
maxAmp = max(abs(y));
fprintf('Max amplitude: %.4f\n', maxAmp);
fprintf('RMS level: %.4f\n', rms(y));

if maxAmp < 0.15
    fprintf('\n*** WARNING: Recording too quiet! ***\n');
    fprintf('*** Increase volume / move mic closer / reduce room noise, then try again ***\n\n');
end

sound(y, Fs);
pause(recordDuration + 0.5);

audiowrite('C:\CEP_Project\query_test.wav', y, Fs);
fprintf('Saved recording.\n\n');

%% Preprocess
if size(y,2) == 2
    y = mean(y,2);
end
targetFs = 8000;
yProcessed = resample(y, targetFs, Fs);
yEmph = filter([1 -0.95], 1, yProcessed);   % pre-emphasis: must match build_database.m

%% Load database
load('C:\CEP_Project\database\fingerprintDB.mat');

%% Fingerprint query
S = abs(spectrogram(yEmph, 1024, 512, 1024, targetFs));
peaks = extractPeaks(S);
fprintf('Query peaks found: %d\n', size(peaks,1));

%% Match
fanoutFactor = 15;   % increased from 5 - more hash pairs = more robust to noise
targetTimeWindow = 100;
voteMap = containers.Map('KeyType','char','ValueType','double');

for i = 1:size(peaks,1)
    f1 = peaks(i,1); t1 = peaks(i,2);
    for j = i+1:min(i+fanoutFactor, size(peaks,1))
        f2 = peaks(j,1); t2 = peaks(j,2);
        dt = t2 - t1;
        if dt > 0 && dt <= targetTimeWindow
            hashKey = f1*1e6 + f2*1e3 + dt;
            if isKey(fingerprintDB, hashKey)
                matches = fingerprintDB(hashKey);
                for m = 1:size(matches,1)
                    songID = matches(m,1);
                    offset = matches(m,2) - t1;
                    voteKey = sprintf('%d_%d', songID, offset);
                    if isKey(voteMap, voteKey)
                        voteMap(voteKey) = voteMap(voteKey) + 1;
                    else
                        voteMap(voteKey) = 1;
                    end
                end
            end
        end
    end
end

allKeys = keys(voteMap);
bestVotes = 0; bestKey = '';
for k = 1:length(allKeys)
    if voteMap(allKeys{k}) > bestVotes
        bestVotes = voteMap(allKeys{k});
        bestKey = allKeys{k};
    end
end

if isempty(bestKey)
    fprintf('\n=== NO MATCH FOUND ===\n');
else
    parts = strsplit(bestKey, '_');
    winningSongID = str2double(parts{1});
    fprintf('\n=== MATCH RESULT ===\n');
    fprintf('Best match: %s\n', songList{winningSongID});
    fprintf('Votes: %d\n', bestVotes);
end
