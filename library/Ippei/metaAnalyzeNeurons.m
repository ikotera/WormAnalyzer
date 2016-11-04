function metaAnalyzeNeurons(path)

flgTS = false;
flgMultiColumnNeuronLabels = false;
numHeatmaps = 2;

path = [path, '\'];
date = path(end-11:end-1);
if exist([path, ls([path, 'Variables*.mat'])], 'file');
    load([path, ls([path, 'Variables*.mat'])], 'infoND');
else
    prt('No Variables*.mat file found'); return
end
if exist([path, 'neurons.mat'], 'file');
    load([path, 'neurons.mat'], 'neurons');
else
    prt('No neurons.mat file found'); return
end

numPlanes = numel(neurons);
for np = 1:numPlanes
    numNeurons(np) = numel(neurons{np});
end

numTotalNeurons = sum(numNeurons);

numResampledTimePoints = 540;
tsResampled = nan(numResampledTimePoints, numTotalNeurons);

warning('off', 'MATLAB:linearinter:noextrap');

for np = 1:numPlanes
    
    for nn = 1:numNeurons(np)

        tsRow = neurons{np}{nn}.('int_ratio');
        namesNeuron{1, sum(numNeurons(1:np)) + nn - numNeurons(np)} = neurons{np}{nn}.('name'); %#ok<AGROW>
        tm = infoND(infoND(infoND(:, 2) == np), 4);
        
        lenTs = numel(tsRow);

        subtTs = tsRow - min(tsRow);
        % Create time series object
        objTs = timeseries(subtTs', tm(1:length(subtTs)), 'Name', 'neuron');
        
        % Resample the TS to uniform intervals
        objResampled  = resample(objTs, 1:1:numResampledTimePoints, 'linear');
        
        tsResampled(:, sum(numNeurons(1:np)) + nn - numNeurons(np)) = objResampled.data;
        
    end
    
end

tsResampled(all(isnan(tsResampled), 2), :) = [];
% Get rid of rows that have at least one NaN
tsResampled(any(isnan(tsResampled), 2), :) = [];

warning('on', 'MATLAB:linearinter:noextrap');

%% Merge time-series

nTemp = 1;
threshCorr = 0.8;
isNamed = cellfun(@(x) ~strcmp(x(1:3), 'neu'), namesNeuron);
nonNamedNames = namesNeuron(:, ~isNamed);
nonNamed = tsResampled(:, ~isNamed);
numNonNamed = size(nonNamed, 2);
mergedTs = nan(size(tsResampled, 1), numNonNamed);

while numNonNamed > nTemp
    xc = nan(numNonNamed, 1);
    
    % Find correlation coef. among non-named neurons for a non-named neuron
    for nScan = 1:numNonNamed
        xc(nScan) = corr(nonNamed(:, nTemp), nonNamed(:, nScan));
    end
    if numel(find(xc > threshCorr)) > 1
        
        % Take average of all neurons with higher than threshold correlation
        mergedTs(:, nTemp) = mean(nonNamed(:, xc > threshCorr), 2);
        
        % Delete neurons with higher than threshold correlation except for
        % the template neuron (whose correlation is 1).
        nonNamed(:, xc < 0.9999999999999 & xc > threshCorr) = [];
    else
        mergedTs(:, nTemp) = nonNamed(:, nTemp);
    end
    
    prt(nTemp, nonNamedNames{nTemp});
    
    nTemp = nTemp + 1;
    numNonNamed = size(nonNamed, 2);
    clear xc;
end



nTemp = 1;
namedTs = tsResampled(:, isNamed);
namedNames = namesNeuron(:, isNamed);
numNamed = size(namedNames, 2);
mergedNamedTs = nan(size(tsResampled, 1), numNamed);
mergedNames = cell(1, numNamed);

while numNamed > nTemp
    sn = false(numNamed, 1);
    
    % Find the same names among named neurons
    for nScan = 1:numNamed
        sn(nScan) = strcmp(namedNames(:, nTemp), namedNames(:, nScan));
    end
    if sum(sn) > 1
        
        % Take average of all neurons with higher than threshold correlation
        mergedNamedTs(:, nTemp) = mean(namedTs(:, sn), 2);
        mergedNames(1, nTemp) = namedNames(1, nTemp);
        
        
        
        % Delete neurons with higher than threshold correlation except for
        % the template neuron (whose correlation is 1).
        namedTs(:, sn) = [];
        namedNames(:, sn) = [];
    else
        mergedNamedTs(:, nTemp) = namedTs(:, nTemp);
        mergedNames(1, nTemp) = namedNames(1, nTemp);
    end
    
    prt(nTemp, mergedNames{nTemp});
    
    nTemp = nTemp + 1;
    numNamed = size(namedTs, 2);
    clear sn;
end

mergedTs(:, any(isnan(mergedTs), 1)) = [];
mergedNamedTs(:, any(isnan(mergedNamedTs), 1)) = [];
mergedNames( cellfun(@isempty, mergedNames) ) = []; % Vectorized way to get rid of empty cells
mergedNames = [mergedNames, repmat({''}, 1, size(mergedTs, 2))];
mergedTs = [mergedNamedTs, mergedTs];


%% Sort matrix according to correlation

numTotalNeurons = size(mergedTs, 2);

[~, maxC] = find(strcmp(mergedNames, 'AFDL'), 1, 'first');

if isempty(maxC)
    maxC = 1;
end

xc = nan(numTotalNeurons, 1);
for nScan = 1:numTotalNeurons
    
    xc(nScan) = corr(mergedTs(:, maxC), mergedTs(:, nScan));
%     xc(nScan) = corr(mergedTs(180:400, maxC), mergedTs(180:400, nScan));
end

xci = round((xc + 1) * 1000000000);

[~, ixc] = sort(xci, 'descend');

sortedTs = mergedTs(:, ixc);
sortedNames = mergedNames(1, ixc);

numTs = size(sortedTs, 2);
neuronsPerMap = ceil(numTs / numHeatmaps);
clims = [0 3];

for m = 1:numHeatmaps
    
    st = neuronsPerMap * (m - 1) + 1;
    ed = neuronsPerMap * m;
    if ed > numTs
        ed = numTs;
    end
    hF = plotTS( sortedTs(:, st:ed), sortedNames(:, st:ed), clims );
    savefig(hF, [path, 'Heatmap', num2str(m), '.fig']);
    print(hF,'-dpsc2', [path, 'Heatmap', num2str(m), '.eps']);
end

% Time series

if ~flgTS
    return;
end

maxY = max(sortedTs(:));
minY = min(sortedTs(:));
maxX = size(sortedTs, 1);

heightPlot = 90;
widthPlot = 300;

spacerTop = 20;
factorResize = 0.8;

pl = 1;
sl = 1;


while sl
    [slide, ap, ppt] = activatePptSlide;
    
    if sl == 1
        heightSlide = ap.PageSetup.SlideHeight;
        widthSlide = ap.PageSetup.SlideWidth;
        
        numPlotRows = floor(heightSlide / (heightPlot * factorResize));
        numPlotCols = floor(widthSlide / (widthPlot * factorResize));
        
        numPlotsPerSlide = numPlotRows * numPlotCols;
        numSlides = ceil(numTs / numPlotsPerSlide);
        numPlotsRem = rem(numTs, numPlotsPerSlide);
    end
    
    if sl == numSlides
        numPlotsPerSlide = numPlotsRem;
    end
    
    for cs = 1:numPlotCols
        for rs = 1:numPlotRows
            while pl <= numTs
                if ~strcmp(sortedNames{pl}, ' ')
                    f = figure('Position', [100, 100, widthPlot, heightPlot]);
                    plot(sortedTs(:, pl));
                    title(sortedNames{pl});
                    xlim([0, maxX]);
                    %                     ylim([minY, maxY]);
                    print('-dbitmap', ['-f' num2str(f.Number)], ...
                        ['-r' num2str(150)]);
                    
                    pic = invoke(slide.Shapes,'PasteSpecial', 1);
                    
                    % Set position
                    set(pic,'Left', (widthPlot * cs - widthPlot) * factorResize,...
                        'Top', spacerTop + (heightPlot * rs - heightPlot) * factorResize);
                    %                 'Width', widthPlot, 'Height', heightPlot);
                    
                    % Save the neuron in mat file
                    tsNeuron = sortedTs(:, pl);
                    save([path, 'TS_', sortedNames{pl}, '_', date, '.mat'], 'tsNeuron');
                    
                    delete(f);
                    pl = pl + 1;
                    
                    break;
                    %                     if pl >= numPlots, break; end
                end
                pl = pl + 1;
            end
        end
        if pl >= numTs, break; end
    end
    if pl >= numTs, break; end

    sl = sl + 1;
end

ap.SaveAs([path, 'neurons.ppt']);
ppt.Quit;
ppt.delete;


%% Plot Heat Map and Time Series
    function hF = plotTS(sTS, sN, clims)
        
        % sortedTs = sortedTs ./ repmat(mean(sortedTs, 2), 1, numTs);
        
        % Heat map
        hF = figure; hI = axes; imagesc(sTS', clims);
        colormap('jet');
        set(hF, 'Position', [320 50 300 1400]);
        set(hI, 'Position', [0.23 0.07 0.6 0.9]);
        set(hI, 'YAxisLocation', 'right');
        ylabel('Neurons');
        set(hI, 'TickLength', [0 0]);
        xlabel('Time (s)');
        % set(hI, 'XTick', []);
        % title(path(9:end-1),'interpreter','none');
        hB = colorbar;
        set(hB, 'TickLength', 0, 'Position', [0.89405 0.069512 0.047619 0.3]);
        
        last = true; tx = 1; cl = 1;
        while last
            if ~strcmp(sN{tx}, '')
                if flgMultiColumnNeuronLabels
                    if cl == 1
                        text(-180, tx, sN{tx}, 'FontSize', 8, 'FontName', 'Tahoma');
                    elseif cl == 2
                        text(-120, tx, sN{tx}, 'FontSize', 8, 'FontName', 'Tahoma');
                    else
                        text(-60, tx, sN{tx}, 'FontSize', 8, 'FontName', 'Tahoma');
                        cl = 0;
                    end
                    cl = cl + 1;
                else
                    text(-120, tx, sN{tx}, 'FontSize', 8, 'FontName', 'Tahoma');
                end
                
            end
            tx = tx + 1;
            if tx > length(sN), last = false; end
        end
%         savefig(hF, [path, 'Heatmap.fig']);
        % delete(hF);
    end

end

