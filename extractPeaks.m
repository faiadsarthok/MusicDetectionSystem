function peaks = extractPeaks(S)
    freqBlock = 8; 
    timeBlock = 8;   
    [numFreq, numTime] = size(S);
    peaks = [];
    
    energyThreshold = 0.03 * max(S(:));  
    
    for tStart = 1:timeBlock:numTime
        tEnd = min(tStart+timeBlock-1, numTime);
        for fStart = 1:freqBlock:numFreq
            fEnd = min(fStart+freqBlock-1, numFreq);
            block = S(fStart:fEnd, tStart:tEnd);
            
            [maxVal, idx] = max(block(:));
            if maxVal > energyThreshold
                [fRel, tRel] = ind2sub(size(block), idx);
                peaks = [peaks; fStart+fRel-1, tStart+tRel-1];
            end
        end
    end
end