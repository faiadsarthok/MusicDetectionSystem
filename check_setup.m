%% ============ DIAGNOSTIC CHECK - RUN THIS FIRST ============
fprintf('--- FOLDER CHECK ---\n');
folders = {'C:\CEP_Project\audio\', 'C:\CEP_Project\processed\', 'C:\CEP_Project\database\', 'C:\CEP_Project\scripts\'};
for i = 1:length(folders)
    if exist(folders{i}, 'dir')
        fprintf('OK: %s exists\n', folders{i});
    else
        fprintf('MISSING: %s\n', folders{i});
    end
end

fprintf('\n--- AUDIO FOLDER ---\n');
audioFiles = dir('C:\CEP_Project\audio\*.wav');
fprintf('Files in audio\\: %d\n', length(audioFiles));

fprintf('\n--- PROCESSED FOLDER ---\n');
procFiles = dir('C:\CEP_Project\processed\*.wav');
fprintf('Files in processed\\: %d\n', length(procFiles));
if ~isempty(procFiles)
    info = audioinfo(fullfile(procFiles(1).folder, procFiles(1).name));
    fprintf('Sample rate of first processed file (%s): %d Hz\n', procFiles(1).name, info.SampleRate);
    fprintf('  -> This MUST say 8000. If not, rerun preprocess_all.m\n');
end

fprintf('\n--- DATABASE CHECK ---\n');
dbPath = 'C:\CEP_Project\database\fingerprintDB.mat';
if exist(dbPath, 'file')
    d = dir(dbPath);
    fprintf('Database file exists. Last modified: %s\n', d.date);
    load(dbPath);
    fprintf('Total hashes: %d\n', fingerprintDB.Count);
    fprintf('Total songs: %d\n', length(songList));
    fprintf('First song: %s\n', songList{1});
else
    fprintf('MISSING: fingerprintDB.mat not found at %s\n', dbPath);
end

fprintf('\n--- extractPeaks.m CHECK ---\n');
w = which('extractPeaks');
fprintf('extractPeaks.m location: %s\n', w);
if isempty(w)
    fprintf('  -> PROBLEM: extractPeaks.m is not visible to MATLAB right now.\n');
    fprintf('  -> Fix: make sure your Current Folder (top-left in MATLAB) is C:\\CEP_Project\\scripts\\\n');
end

fprintf('\n--- DONE. Copy this whole output and share it. ---\n');
