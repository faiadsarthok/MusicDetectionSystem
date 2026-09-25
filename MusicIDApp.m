function MusicIDApp
    databasePath = 'C:\CEP_Project\database\fingerprintDB.mat';
    audioFolder  = 'C:\CEP_Project\audio\';
    targetFs     = 8000;                      
    Fs           = 48000;                     
    maxRecordSec = 30;                        
    meterPeriod  = 0.2;                       
    rmsNoiseGate = 0.0015;                    

    recObj = [];
    isRecording = false;
    elapsedSec = 0;
    fingerprintDB = [];
    songList = {};
    songFeatures = []; 
    matchedFile = '';
    player = [];

    if ~exist(databasePath, 'file')
        error('Database not found at %s. Run build_database.m first.', databasePath);
    end
    loaded = load(databasePath);
    fingerprintDB = loaded.fingerprintDB;
    songList = loaded.songList;
    
    if isfield(loaded, 'songFeatures')
        songFeatures = loaded.songFeatures;
    else
        warning('songFeatures not found in database. Recommendations disabled.');
    end

    bgColor        = [0.04 0.04 0.04];
    panelColor     = [0.08 0.08 0.08];
    trackColor     = [0.15 0.05 0.05];
    accentRed      = [0.85 0.10 0.15];
    accentLightRed = [1.00 0.25 0.30];
    accentDarkRed  = [0.50 0.05 0.08];
    accentYellow   = [1.00 0.75 0.10];
    textWhite      = [0.95 0.95 0.95];
    textDim        = [0.55 0.55 0.55];
    meterX = 560; meterY = 130; meterW = 60; meterH = 320;

    fig = uifigure('Name', 'Audio Pattern Recognition', 'Position', [450 220 660 560], 'Color', bgColor);
    
    uilabel(fig, 'Text', sprintf('%d songs in database', length(songList)), ...
        'FontSize', 12, 'FontColor', textDim, 'Position', [32 500 300 20]);
        
    statusLabel = uilabel(fig, 'Text', 'Ready. Press Start, then play the song.', ...
        'FontSize', 13, 'FontColor', textDim, 'Position', [30 465 460 25]);
        
    timerLabel = uilabel(fig, 'Text', '00:00', 'FontSize', 34, 'FontWeight', 'bold', ...
        'FontColor', textWhite, 'Position', [140 385 200 55], 'HorizontalAlignment', 'center');
        
    startBtn = uibutton(fig, 'Text', 'Start Recording', 'FontSize', 14, 'FontWeight', 'bold', ...
        'BackgroundColor', accentRed, 'FontColor', [1 1 1], ...
        'Position', [60 325 170 46], 'ButtonPushedFcn', @startRecording);
    stopBtn = uibutton(fig, 'Text', 'Stop Recording', 'FontSize', 14, 'FontWeight', 'bold', ...
        'BackgroundColor', accentDarkRed, 'FontColor', [0.8 0.8 0.8], ...
        'Position', [260 325 170 46], 'ButtonPushedFcn', @stopRecording, 'Enable', 'off');

    uilabel(fig, 'Text', 'MIC LEVEL', 'FontSize', 11, 'FontWeight', 'bold', ...
        'FontColor', textDim, 'Position', [meterX-15 490 90 20], 'HorizontalAlignment', 'center');
    meterTrack = uipanel(fig, 'Title', '', 'BackgroundColor', trackColor, ...
        'Position', [meterX meterY+20 meterW meterH]);
    meterFill = uipanel(fig, 'Title', '', 'BackgroundColor', accentRed, ...
        'Position', [meterX meterY+20 meterW 0]);

    resultPanel = uipanel(fig, 'Title', '', 'Position', [30 20 500 270], ...
        'BackgroundColor', panelColor);
        
    resultTitleLabel = uilabel(resultPanel, 'Text', 'No match yet', 'FontSize', 17, ...
        'FontWeight', 'bold', 'FontColor', textWhite, 'Position', [20 200 460 45], 'WordWrap', 'on');
    confidenceLabel = uilabel(resultPanel, 'Text', '', 'FontSize', 12, ...
        'FontColor', accentLightRed, 'Position', [20 170 460 25]);
        
    recTitleLabel = uilabel(resultPanel, 'Text', 'Recommended Similar Tracks:', 'FontSize', 12, ...
        'FontWeight', 'bold', 'FontColor', accentYellow, 'Position', [20 135 460 20], 'Visible', 'off');
    recLabel = uilabel(resultPanel, 'Text', '', 'FontSize', 12, ...
        'FontColor', textWhite, 'Position', [20 75 460 55], 'WordWrap', 'on');
        
    playBtn = uibutton(resultPanel, 'Text', '▶  Play', 'FontSize', 14, 'FontWeight', 'bold', ...
        'BackgroundColor', accentRed, 'FontColor', [1 1 1], ...
        'Position', [50 20 110 40], 'ButtonPushedFcn', @playSong, 'Enable', 'off');
    stopPlayBtn = uibutton(resultPanel, 'Text', '■  Stop', 'FontSize', 14, 'FontWeight', 'bold', ...
        'BackgroundColor', [0.2 0.2 0.2], 'FontColor', [1 1 1], ...
        'Position', [180 20 110 40], 'ButtonPushedFcn', @stopSong, 'Enable', 'off');

    function startRecording(~, ~)
        recObj = audiorecorder(Fs, 16, 1);
        recObj.TimerPeriod = meterPeriod;
        recObj.TimerFcn = @onTick;
        recObj.StopFcn = @onRecordingStopped;
        elapsedSec = 0;
        isRecording = true;
        
        startBtn.Enable = 'off';
        stopBtn.Enable = 'on';
        stopBtn.FontColor = [1 1 1];
        statusLabel.Text = 'Recording... play the song now';
        resultTitleLabel.Text = 'Listening...';
        confidenceLabel.Text = '';
        recTitleLabel.Visible = 'off';
        recLabel.Text = '';
        playBtn.Enable = 'off';
        stopPlayBtn.Enable = 'off';
        timerLabel.Text = '00:00';
        setMeter(0);
        
        record(recObj, maxRecordSec);
    end

    function setMeter(level)
        level = max(0, min(1, level));
        fillH = round(level * meterH);
        meterFill.Position = [meterX, meterY+20, meterW, fillH];
        if level < 0.6
            meterFill.BackgroundColor = accentDarkRed;
        elseif level < 0.85
            meterFill.BackgroundColor = accentRed;
        else
            meterFill.BackgroundColor = accentLightRed;
        end
    end

    function onTick(~, ~)
        if ~isRecording, return; end
        elapsedSec = elapsedSec + meterPeriod;
        timerLabel.Text = sprintf('%02d:%02d', floor(elapsedSec/60), floor(mod(elapsedSec,60)));
        try
            currentData = getaudiodata(recObj);
            chunkLen = min(length(currentData), round(meterPeriod*Fs*1.5));
            if chunkLen > 0
                chunk = currentData(end-chunkLen+1:end);
                level = rms(chunk) * 12;   
                setMeter(level);
            end
        catch ME
            statusLabel.Text = ['Meter error: ' ME.message];
        end
    end

    function stopRecording(~, ~)
        if ~isRecording, return; end
        stop(recObj);
    end

    function onRecordingStopped(~, ~)
        if ~isRecording, return; end
        isRecording = false;
        setMeter(0);
        startBtn.Enable = 'on';
        stopBtn.Enable = 'off';
        stopBtn.FontColor = [0.8 0.8 0.8];
        statusLabel.Text = 'Processing...';
        drawnow;
        y = getaudiodata(recObj);
        processAndMatch(y);
    end

    function processAndMatch(y)
        if size(y,2) == 2, y = mean(y,2); end
        
        rawMaxAmp = max(abs(y));
        rawRMS = rms(y);
        
        if rawRMS < rmsNoiseGate
            statusLabel.Text = 'Too quiet / mostly silence — move closer, increase volume';
            resultTitleLabel.Text = 'No match';
            return;
        end
        
        y = y / rawMaxAmp * 0.95;
        yProcessed = resample(y, targetFs, Fs);
        yEmph = filter([1 -0.95], 1, yProcessed);
        S = abs(spectrogram(yEmph, 1024, 512, 1024, targetFs));
        peaks = extractPeaks(S);
        
        if size(peaks,1) < 5
            statusLabel.Text = 'Not enough musical content detected';
            resultTitleLabel.Text = 'No match';
            return;
        end
        
        fanoutFactor = 15;
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
        
        allKeys = keys(voteMap);
        if isempty(allKeys)
            statusLabel.Text = 'No match found — try again';
            resultTitleLabel.Text = 'No match';
            return;
        end
        
        bestVotes = 0; bestKey = '';
        for k = 1:length(allKeys)
            if voteMap(allKeys{k}) > bestVotes
                bestVotes = voteMap(allKeys{k});
                bestKey = allKeys{k};
            end
        end
        
        parts = strsplit(bestKey, '_');
        winningSongID = str2double(parts{1});
        [~, cleanTitle, ~] = fileparts(songList{winningSongID});
        matchedFile = songList{winningSongID};
        
        statusLabel.Text = 'Match found!';
        resultTitleLabel.Text = cleanTitle;
        confidenceLabel.Text = sprintf('Confidence votes: %d', bestVotes);
        playBtn.Enable = 'on';
        stopPlayBtn.Enable = 'on';
        
        if ~isempty(songFeatures) && size(songFeatures,1) >= winningSongID
            targetFeat = songFeatures(winningSongID, :);
            dists = sqrt(sum((songFeatures - targetFeat).^2, 2));
            dists(winningSongID) = inf; 
            [~, sortIdx] = sort(dists);
            
            recText = '';
            numRecs = min(3, length(songList)-1);
            for r = 1:numRecs
                [~, recName, ~] = fileparts(songList{sortIdx(r)});
                recText = sprintf('%s%d. %s\n', recText, r, recName);
            end
            
            recTitleLabel.Visible = 'on';
            recLabel.Text = recText;
        end
    end

    function playSong(~, ~)
        if isempty(matchedFile), return; end
        [songY, songFs] = audioread(fullfile(audioFolder, matchedFile));
        player = audioplayer(songY, songFs);
        play(player);
    end

    function stopSong(~, ~)
        if ~isempty(player) && isvalid(player) && isplaying(player)
            stop(player);
        end
    end
end