function [meanTS, SDR, SEMR] = averageVariable(path, nameVar, numSampling, intervalSampling)
% [meanTS, SDR, SEMR] = averageVariable(path, nameVar, numSampling, intervalSampling);
% Calculates mean of specified variable in all the mat files in a specified folder.
% Example:
% meanV = averageVariable('E:\Ippei\140130 TEC_20-26_5D_calibration', 'tempDaq', 540, 4);


%% File Handling
if ~exist('path', 'var')
    % Prompt the user to choose a file
    path = uigetdir(...
        'C:\', 'Select a Folder that contains mat files');
    if path == 0
        return;
    end
end

%% Get a list of mat files in the folder and subfolders
listMat = rdir([path, '\**\Variables_*.mat']);
numMatFiles = numel(listMat);


%% Calculate mean
warning off %#ok<*WNOFF>
for nm = 1:numMatFiles

    s = load(listMat(nm).name, nameVar);

    objTS = timeseries(s.(nameVar)(:, 1), s.(nameVar)(:, 2), 'Name', 'temp');
    
    rts  = resample(objTS, 1:intervalSampling:numSampling);
    
    stackTS(:, 1, nm) = rts.Data; %#ok<*AGROW>
    stackTS(:, 2, nm) = rts.Time;
    
end    
warning on %#ok<*WNON>
    meanTS = mean(stackTS, 3);
    SDR = std(stackTS, 0, 3);
    SEMR = SDR ./ sqrt(size(stackTS, 3));

end