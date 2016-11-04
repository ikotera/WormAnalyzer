function batchPlotNeurons(pathInput)
% batchPlotNeurons(pathInput);
%

% Get a list of sortedNeurons.mat files in the folder and subfolders
listFile = rdir([pathInput, '\**\sortedNeurons.mat']);
numFiles = numel(listFile);

if numFiles < 1
    prt('sortedNeurons.mat file not found.');
    return;
end

for nf = 1:numFiles
    
    % Load the mat files and get a list of all the neurons
    [path, ~, ~] = fileparts(listFile(nf).name);
    path = [path, '\']; %#ok<AGROW>
    load([path, 'sortedNeurons.mat'], 'sortedNeurons');
    numNeurons = size(sortedNeurons, 2); %#ok<USENS>

    for nn = 1:numNeurons
        figure;
        
        ratios = cat(2, sortedNeurons{2, nn}{1, :});
        [dimY, dimX] = size(ratios);
        minDimY = min(dimY);
        nameNeuron = sortedNeurons{1, nn};
        
        plot(ratios);
        legend(sortedNeurons{2, nn}{2, :});
        title(['Raw Ratios, ', nameNeuron]);
        xlim([0 minDimY]);ylim([min(ratios(:)) max(ratios(:))]);
        
        % Plot mean and SE
        meanRatio = mean(ratios, 2);
        SDR = std(ratios, 0, 2);
        SEMR = SDR ./ sqrt(size(ratios, 2));
        figure('Position', [100, 100, 480, 300]);
        errorbar(1:3:minDimY, meanRatio(1:3:minDimY), SEMR(1:3:minDimY));
        xlim([0 minDimY]);ylim([min(ratios(:)) max(ratios(:))]);
        title(['Mean Ratio with Standard Errors, ', nameNeuron]);
        xlabel('time (s)');
        ylabel('Ratio Values (G/R)');
        
        % Plot ratios of all the neurons with mean
        figure('Position', [100, 100, 500, 300]);
        hold on
        plot(ratios, 'b');plot(meanRatio, 'r', 'LineWidth', 3);
        hold off
        xlim([0 minDimY]);ylim([min(ratios(:)) max(ratios(:))]);
        title(['All the Raw Ratios (blue) with Mean (red), ', nameNeuron]);
        xlabel('time (s)');
        ylabel('Ratio Values (G/R)');
        
        
        
    end
    
    dimX = size(sortedNeurons{2, 1}{1, 1}, 1);
    xlim([0 dimX]);
    
end

end