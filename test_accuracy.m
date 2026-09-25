

load('C:\CEP_Project\database\fingerprintDB.mat');

processedFolder = 'C:\CEP_Project\processed\';
files = dir(fullfile(processedFolder, '*.wav'));
targetFs = 8000;
clipDuration = 5;

fanoutFactor = 15;
targetTimeWindow = 100;

correct = 0;
total = length(files);

for songID = 1:total
    filepath = fullfile(processedFolder, files(songID).name);
    [y, Fs] = audioread(filepath);

   
    maxStart = length(y) - clipDuration*Fs;
    startSample = randi([round(Fs*10), max(round(Fs*10)+1, maxStart)]);
    clip = y(startSample : startSample + clipDuration*Fs - 1);

    clipEmph = filter([1 -0.95], 1, clip);
    S = abs(spectrogram(clipEmph, 1024, 512, 1024, targetFs));
    peaks = extractPeaks(S);

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
                        voteKey = sprintf('%d_%d', matches(m,1), matches(m,2)-t1);
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

    bestVotes = 0; predictedID = -1;
    allKeys = keys(voteMap);
    for k = 1:length(allKeys)
        if voteMap(allKeys{k}) > bestVotes
            bestVotes = voteMap(allKeys{k});
            parts = strsplit(allKeys{k}, '_');
            predictedID = str2double(parts{1});
        end
    end

    if predictedID == -1
        predictedName = 'NO MATCH';
        isCorrect = false;
    else
        predictedName = songList{predictedID};
        isCorrect = (predictedID == songID);
    end

    correct = correct + isCorrect;

    fprintf('%d/%d | True: %-30s | Predicted: %-30s | Votes: %d | %s\n', ...
        songID, total, files(songID).name, predictedName, bestVotes, ...
        string(isCorrect));
end

accuracy = 100 * correct / total;
fprintf('\n=== ACCURACY: %.1f%% (%d/%d correct) ===\n', accuracy, correct, total);
