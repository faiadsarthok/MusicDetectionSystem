%% ============ ADD ONE NEW SONG TO EXISTING DATABASE ============
% Use this whenever you want to add a song WITHOUT rebuilding everything.
%
% BEFORE RUNNING:
% 1. Put the new song's original wav file in C:\CEP_Project\audio\
% 2. Set newSongFile below to its exact filename

newSongFile = 'PUT_NEW_SONG_FILENAME_HERE.wav';

audioFolder     = 'C:\CEP_Project\audio\';
processedFolder = 'C:\CEP_Project\processed\';
databaseFile    = 'C:\CEP_Project\database\fingerprintDB.mat';
targetFs = 8000;
fanoutFactor = 5;
targetTimeWindow = 100;

%% Preprocess the new song
[y, Fs] = audioread(fullfile(audioFolder, newSongFile));
if size(y,2) == 2
    y = mean(y,2);
end
y = resample(y, targetFs, Fs);
audiowrite(fullfile(processedFolder, newSongFile), y, targetFs);

%% Load existing database
load(databaseFile);  % loads fingerprintDB, songList

newSongID = length(songList) + 1;
songList{newSongID} = newSongFile;

%% Fingerprint the new song
yEmph = filter([1 -0.95], 1, y);   % pre-emphasis: must match build_database.m
S = abs(spectrogram(yEmph, 1024, 512, 1024, targetFs));
peaks = extractPeaks(S);

for i = 1:size(peaks,1)
    f1 = peaks(i,1); t1 = peaks(i,2);
    for j = i+1:min(i+fanoutFactor, size(peaks,1))
        f2 = peaks(j,1); t2 = peaks(j,2);
        dt = t2 - t1;
        if dt > 0 && dt <= targetTimeWindow
            hashKey = f1*1e6 + f2*1e3 + dt;
            entry = [newSongID, t1];
            if isKey(fingerprintDB, hashKey)
                fingerprintDB(hashKey) = [fingerprintDB(hashKey); entry];
            else
                fingerprintDB(hashKey) = entry;
            end
        end
    end
end

%% Save updated database
save(databaseFile, 'fingerprintDB', 'songList', '-v7.3');
fprintf('Added "%s" as song ID %d. Total songs now: %d\n', newSongFile, newSongID, newSongID);
