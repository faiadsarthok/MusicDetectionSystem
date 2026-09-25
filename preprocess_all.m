%% ============ PREPROCESS ALL SONGS (mono + downsample) ============
audioFolder  = 'C:\CEP_Project\audio\';
outputFolder = 'C:\CEP_Project\processed\';
targetFs = 8000;

if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

files = dir(fullfile(audioFolder, '*.wav'));

for i = 1:length(files)
    filepath = fullfile(audioFolder, files(i).name);
    [y, Fs] = audioread(filepath);

    if size(y,2) == 2
        y = mean(y, 2);
    end

    y = resample(y, targetFs, Fs);

    outPath = fullfile(outputFolder, files(i).name);
    audiowrite(outPath, y, targetFs);

    fprintf('Processed %d/%d: %s\n', i, length(files), files(i).name);
end

fprintf('Done! All songs processed.\n');
