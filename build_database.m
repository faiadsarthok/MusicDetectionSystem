processedFolder = 'C:\CEP_Project\processed\';
databaseFolder  = 'C:\CEP_Project\database\';
files = dir(fullfile(processedFolder, '*.wav'));
numSongs = length(files);
fanoutFactor = 15; 
targetTimeWindow = 100;
targetFs = 8000; 

fingerprintDB = containers.Map('KeyType','double','ValueType','any');
songList = cell(numSongs,1);

songFeatures = zeros(numSongs, 2); 

for songID = 1:numSongs
    filepath = fullfile(processedFolder, files(songID).name);
    songList{songID} = files(songID).name;
    [y, Fs] = audioread(filepath);
    
    if size(y, 2) > 1
        y = mean(y, 2);
    end
    if Fs ~= targetFs
        y = resample(y, targetFs, Fs);
        Fs = targetFs;
    end
    
    zcr = sum(abs(diff(y > 0))) / length(y);
    
    Y = abs(fft(y));
    halfLength = floor(length(Y)/2);
    Y_half = Y(1:halfLength);
    freqs = (0:halfLength-1)' * (Fs / length(Y));
    
    if sum(Y_half) == 0
        centroid = 0;
    else
        centroid = sum(freqs .* Y_half) / sum(Y_half);
    end
    
    
    songFeatures(songID, :) = [centroid, zcr];
    
    yEmph = filter([1 -0.95], 1, y);   
    S = abs(spectrogram(yEmph, 1024, 512, 1024, Fs));
    peaks = extractPeaks(S);
    
    for i = 1:size(peaks,1)
        f1 = peaks(i,1); t1 = peaks(i,2);
        for j = i+1:min(i+fanoutFactor, size(peaks,1))
            f2 = peaks(j,1); t2 = peaks(j,2);
            dt = t2 - t1;
            if dt > 0 && dt <= targetTimeWindow
                hashKey = f1*1e6 + f2*1e3 + dt;
                entry = [songID, t1];
                if isKey(fingerprintDB, hashKey)
                    fingerprintDB(hashKey) = [fingerprintDB(hashKey); entry];
                else
                    fingerprintDB(hashKey) = entry;
                end
            end
        end
    end
    fprintf('Fingerprinted %d/%d: %s (%d peaks)\n', songID, numSongs, files(songID).name, size(peaks,1));
end

if max(songFeatures(:,1)) > 0
    songFeatures(:,1) = songFeatures(:,1) / max(songFeatures(:,1)); 
end
if max(songFeatures(:,2)) > 0
    songFeatures(:,2) = songFeatures(:,2) / max(songFeatures(:,2)); 
end

if ~exist(databaseFolder, 'dir')
    mkdir(databaseFolder);
end

save(fullfile(databaseFolder, 'fingerprintDB.mat'), 'fingerprintDB', 'songList', 'songFeatures', '-v7.3');
fprintf('DONE. %d unique hashes across %d songs.\n', fingerprintDB.Count, numSongs);