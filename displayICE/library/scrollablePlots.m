function scrollablePlots(argin)

if isa(argin, 'neuronManager')
    nm = argin;
    pathInput = nm.pathInput;
    sortedNeurons = nm.neurons.sorted;
    sL.listFiles = nm.listFiles;
elseif ischar(argin)
    pathInput = argin;
    if exist([pathInput, '\sortedNeurons.mat'], 'file')
        sL = load([pathInput, '\listFiles.mat']);
        load([pathInput, '\sortedNeurons.mat'], 'sortedNeurons');
    elseif exist([pathInput, '\neuronManager.mat'], 'file')
        s = load([pathInput, '\neuronManager.mat']);
        nm = s.nm;
        pathInput = nm.pathInput;
        sortedNeurons = nm.neurons.sorted;
        sL.listFiles = nm.listFiles;
    else
        prt('Run extractAllNeurons first');
        return;
    end
end

listVarMat = rdir([pathInput, '\**\Variables_*.mat']);
sV = load(listVarMat(1).name);

js = getSizeWindows; 
posY = js.screen.height - js.bounds.height + 10; % Height of the Windows Taskbar + 5 pixels

small = false;
widthFig = 800;
heightAxis = 200;
sliderMax = 1100;
sliderKnob = 100;
marginV = 60;
marginH = 40;
posX = 100;
panelCurrent = 1;
sizeFont = 10;

% create figure, panel, and slider
if small
    heightFig = 900;
else
    heightFig = 1100;
end
widthAxis = widthFig - 114;

sizeSlide = sliderMax - sliderKnob;
posLastPlot = (heightFig - heightAxis - marginV) - 180; % Distance for the last plot to move to top

hFig = figure('Menubar','figure', 'Resize','off', 'Name',...
    'Calcium Dynamics',...
    'Numbertitle', 'off', 'Units','pixels', 'Position',[posX posY widthFig+marginH*2 heightFig],...
    'Name', pathInput,...
    'Renderer', 'painters',...
    'WindowScrollWheelFcn', @scrollByWheel);

% Create a panel with axis dimension times numPlot plus margins
hPanelRight = uipanel('Parent', hFig, ...
    'Units','normalized', 'Position', [.87 0 .13 1], 'BorderType', 'none');
hPanelLeft = uipanel('Parent', hFig, ...
    'Units','normalized', 'Position', [0 0 .87 1], 'BorderType', 'none');
hPanelUp = uipanel('Parent', hPanelLeft, ...
    'Units','pixel', 'Position',[0, heightFig - heightAxis - marginV / 2,...
    widthAxis + marginH * 2, heightAxis + marginV]);
hPanelDown = uipanel('Parent', hPanelLeft, ...
    'Units','pixel', 'Position',[0, 0, widthAxis + marginH * 2,...
    heightFig - heightAxis - marginV / 2]);

hBottonGroupPlots = uibuttongroup('Position', [.02 .93 .97 .06], 'Parent', hPanelRight);
uicontrol('Style','radiobutton','String','Raw', 'Unit', 'normalized', ...
    'Position', [0 .74 1 .22], 'parent', hBottonGroupPlots);
uicontrol('Style','radiobutton','String','SEM', 'Unit', 'normalized', ...
    'Position', [0 .38 1 .22], 'parent', hBottonGroupPlots);
uicontrol('Style','radiobutton','String','Mean', 'Unit', 'normalized', ...
    'Position', [0 .03 1 .22], 'parent', hBottonGroupPlots);
set(hBottonGroupPlots,'SelectionChangeFcn',@toggleRadio);

hBottonEPS = uicontrol('Style', 'pushbutton', 'String', 'Export EPS', 'Unit', 'normalized',...
    'Position', [.02 .907 .97 .02], 'Parent', hPanelRight, 'Callback', @exportEPS);

hPopupNorm = uicontrol('Style', 'popup', 'String', 'bottom|normalized|none', 'Unit', 'normalized',...
    'Position', [.02 .886 .95 .018], 'Parent', hPanelRight, 'Callback', @replot);

heightDown = get(hPanelDown, 'Position');
heightDown = heightDown(4);

if isprop(nm, 'laserAmplitude')
    amplitude = nm.laserAmplitude;
    time = nm.laserTime;
    sD.meanDaq = nan;
elseif isfield(sV, 'planLaser')
    [amplitude, time] = parseZapPlan(sV.planLaser, sV.zapPower, sV.duration, sV.zapDuration);
    sD.meanDaq = nan;
elseif sV.tempIni == 20
    if sV.tempFin == 23
        sD = load('\\101.101.1.113\data\Ippei\meanDaq\meanDaq20-23.mat');
    elseif sV.tempFin == 25
        sD = load('\\101.101.1.113\data\Ippei\meanDaq\meanDaq20-25.mat');
    elseif sV.tempFin == 26
        sD = load('\\101.101.1.113\data\Ippei\meanDaq\meanDaq20-26.mat');
    end
else
    sD = load('\\101.101.1.113\data\Ippei\meanDaq\meanDaqNan.mat');
end

if isempty(amplitude)
    amplitude = 0;
    time = 0;
end

% Plot temperature
if ~any(isnan(sD.meanDaq))
    sizeX = max(sD.meanDaq(:, 2));
    minT = min(sD.meanDaq(:, 1));
    minX = min(1:sizeX);
    maxT = max(sD.meanDaq(:, 1));
    maxX = max(1:sizeX);
    
    hAxisTemp = axes('Parent', hPanelUp, ...
        'Units','pixel',...
        'Position', [marginH marginV widthAxis heightAxis-marginV]);
    
    hold on
    
    hPD = plot(sD.meanDaq(:, 2), sD.meanDaq(:, 1),...
        'Parent', hAxisTemp, 'Color', 'blue');
    
    % To speed up the plotting process
    set(hPD, 'EraseMode', 'none');
    
    % static limits of the plots
    xlim(hAxisTemp, [minX maxX]);
    ylim(hAxisTemp, [minT * 0.9 , maxT * 1.1]);
    
    title(hAxisTemp, sprintf('Temperatures'))
    hold off
else
    hAxisTemp = axes('Parent', hPanelUp, 'Units','pixel',...
        'Position', [marginH+1 marginV widthAxis-0 heightAxis-marginV]);
    if max(amplitude) == 0
        ampMax = 1;
    else
        ampMax = max(amplitude);
    end
    plot(hAxisTemp, time, amplitude);
    if isfield(sV, 'modulesLaser')
        xlim(hAxisTemp, [ min( sV.infoND(:, 4) ), max(sV.duration / sV.modulesLaser) ] );
    else
        xlim(hAxisTemp, [ min( sV.infoND(:, 4) ), max(sV.duration) ] );
    end
    ylim(hAxisTemp, [0 - ampMax * 0.1, ampMax * 1.1]);
    title(hAxisTemp, sprintf('Laser Stimuli'));
end

numNeurons = size(sortedNeurons, 1);
numWorms = sortedNeurons{1, 2}{1, 4}; % Number of neurons.mat files (worms)
hPlotRaw = cell(numNeurons, 1);
hEb = cell(numNeurons, 1);

% add and plot to axes one-by-one
hAxisPlot = nan(numNeurons, 1);
colorWorm = lines(numWorms);
colorNeuron = lines(numNeurons);

% Create a panel with axis dimension times numPlot plus margins
for j = 1:3
    hPanelNeurons(j) = uipanel('Parent', hPanelDown, ...
        'Units','pixels', 'Visible', 'on',...
        'Position', [0, 0, widthAxis + marginH * 2, heightAxis * numNeurons + marginV]);
end

set(hPanelNeurons(2), 'Visible', 'on');
set(hPanelNeurons(3), 'Visible', 'off');


plotNeurons;

% Create toggle buttons for selcting worms
hButtonGroupTS = uibuttongroup('Position', [0 .01 1 .87], 'Parent', hPanelRight);

for nw = 1:numWorms + 2
    
    [jButton(nw), hButton(nw)] = javacomponent('javax.swing.JToggleButton');
    set(hButton(nw), 'Parent', hButtonGroupTS, 'Unit', 'normalized', 'Position', [0 1-.02*nw 1 .018]);
    jbh(nw) = handle(jButton(nw), 'CallbackProperties');
    set(jbh(nw), 'ActionPerformedCallback', @toggleWorms);
    if nw == 1
        jButton(nw).setText('Select All');
        set(jButton(nw), 'Name', num2str(-nw));
        jButton(nw).setSelected(true);
    elseif nw == 2
        jButton(nw).setText('Deselect All');
        set(jButton(nw), 'Name', num2str(-nw));        
    else
        jButton(nw).setBorder(javax.swing.border.LineBorder(java.awt.Color(...
            colorWorm(nw-2, 1), colorWorm(nw-2, 2), colorWorm(nw-2, 3)), 2, true));
        jButton(nw).setText(sL.listFiles(nw-2).label);
        set(jButton(nw), 'Name', num2str(nw-2));
        jButton(nw).setSelected(true);
    end
end

% Create JScrollBar object
jscrollbar = javax.swing.JScrollBar();
jscrollbar.setOrientation(jscrollbar.VERTICAL);
jscrollbar.setVisibleAmount(sliderKnob);
% Display the scroll bar
[jScrollBar, hSld] = javacomponent(jscrollbar,...
    [widthAxis+marginH*2-20 0 30 heightDown], hPanelDown);
set(hSld, 'Units', 'normalized', 'Position', [.975 0 .026 1]);
set(jScrollBar, 'AdjustmentValueChangedCallback', {@scrollBySlider},...
    'maximum', sliderMax,...
    'minimum', 0,...
    'unitIncrement', 1,...
    'blockIncrement', 5);

set(hPanelNeurons(panelCurrent), 'Visible', 'on');

set(findall(hFig, '-property', 'FontSize'), 'FontSize', sizeFont);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function plotNeurons

        if ishghandle(hAxisPlot)
            delete(hAxisPlot);
            hAxisPlot = nan(numNeurons, 1);
        end
        
        alpha = 0.25;
        colorNeuron = repmat([0.3 0.3 0.3], numNeurons, 1);
        
        for nn = 1:numNeurons

            idWorm = cat(1, sortedNeurons{nn, 2}{:, 3});       
            for np = 1:3
                
                hAxisPlot(nn, np) = axes('Parent', hPanelNeurons(np), ...
                    'Units', 'pixel',...
                    'Position',...
                    [marginH heightAxis*(numNeurons-nn)+marginV/2 widthAxis heightAxis-marginV]...
                    ); %#ok<*LAXES>
                hold(hAxisPlot(nn, np), 'on');
                movePanel(np, 1);
            end

            ratioNorm = nm.neurons.stats.Ratio{nn};
            timeSamp = nm.neurons.stats.Time{nn};
            meanRatio = nm.neurons.stats.Mean{nn};
            SEMR = nm.neurons.stats.SE{nn};
            nameNeuron = nm.neurons.stats.Properties.RowNames{nn};
            numTP = nm.lenModule;
            

            [~, hEb{nn}(1, 1)] =...
                errorbarShade(timeSamp, meanRatio, SEMR, colorNeuron(nn, :), alpha, hAxisPlot(nn, 2));
            
            % Create plots
            for rs = 1:size(ratioNorm, 2)
                
                hPlotRaw{nn}(rs, 1) = plot(hAxisPlot(nn, 1), timeSamp, ratioNorm(:, rs),...
                    'Color', colorWorm(idWorm(rs), :));
                
%                 hEb{nn}(rs, 1) = errorbar(timeSamp, meanRatio, SEMR,...
%                     'Parent', hAxisPlot(nn, 2));
%                 hEb{nn}(rs, 1) = errorbarShade(timeSamp, meanRatio, SEMR, [0.3 1.0 0.3], alpha, hAxisPlot(nn, 2));
                plot(hAxisPlot(nn, 3), timeSamp, ratioNorm, 'b');

                

            end
            plot(hAxisPlot(nn, 3), timeSamp, meanRatio, 'r', 'LineWidth', 3);
            hold off
            
            axes(hAxisPlot(nn, 1));
            title( [nameNeuron, ', n = ', num2str(rs)] );
            xlim([0 numTP]); ylim([min(ratioNorm(:)) max(ratioNorm(:))]);
            
            axes(hAxisPlot(nn, 2));
            xlim([0 numTP]);
            try % MATLAB HG2
%                 ylim([min(get(hEb{nn}(rs), 'YData') - get(hEb{nn}(rs), 'LData'))...
%                     max(get(hEb{nn}(rs), 'YData') + get(hEb{nn}(rs), 'UData'))]);
                ylim([min(get(hEb{nn}(1), 'YData') )...
                    max(get(hEb{nn}(1), 'YData') )]);
            catch % MATLAB HG1
                ylim([min(get(hEb{nn}(1), 'YData') - get(hEb{nn}(1), 'LData')')...
                    max(get(hEb{nn}(1), 'YData') + get(hEb{nn}(1), 'UData')')]);
            end
            title([nameNeuron, ', n = ', num2str(rs)]);
            
            axes(hAxisPlot(nn, 3));
            xlim([0 numTP]); ylim([min(ratioNorm(:)) max(ratioNorm(:))]);
            title([nameNeuron, ', n = ', num2str(rs)]);
        end
        
        linkaxes([hAxisPlot(:); hAxisTemp], 'x');
        dragzoom;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function exportEPS(~, ~)
        
        
%         hF.RendererMode = 'manual';
        for nn = 1:numNeurons
%             hS{nn} = subplot(numNeurons, 1, nn);
%                     hold on;
            hF = figure('Position', [100, 100, 500, 200]);
            hX = gca;
            
            hA = area(time, amplitude);
            hA.FaceColor = [0.7 0.7 0.7]; hA.EdgeColor = 'none'; hA.FaceAlpha = 0.7;
            ratioNorm = nm.neurons.stats.Ratio{nn};
            timeSamp = nm.neurons.stats.Time{nn};
            meanRatio = nm.neurons.stats.Mean{nn};
            SEMR = nm.neurons.stats.SE{nn};
            nameNeuron = nm.neurons.stats.Properties.RowNames{nn};
            numTP = nm.lenModule;
            
            alpha = 0.7;
            [~, hEb{nn}(1, 1)] =...
                errorbarShade(timeSamp, meanRatio, SEMR, colorNeuron(nn, :), alpha);
            
            xlim([0 numTP]); ylim([min(ratioNorm(:)) max(ratioNorm(:))]);
            ylim([min(get(hEb{nn}(1), 'YData') ) max(get(hEb{nn}(1), 'YData') )]);
            
            
            mn = 0;
            mx = 2.1;
            
            ylabels = linspace(mn, mx, 4);
            set(gca, 'YTick',  ylabels);
            format = repmat( {['%#3.', num2str(1), 'f']}, size(ylabels) );
            cLabel =  cellfun(@num2str, num2cell(ylabels), format, 'uni', 0);
            set(gca, 'YTickLabel', cLabel);
            
            
            ylim([mn mx*1.1]);
            
            xlabel('Time (s)'); ylabel('G/R Ratio');
            title(nameNeuron);
            set(gca, 'box', 'off');
%             uistack(hA, 'bottom'); 
%             RhA.ShowBaseline = 'off';
%             uistack(hF, 'top');
            hX.Layer = 'top';
%             saveas(hF,'filename.eps','eps')
%             saveas(hF,'functionsaveas.eps','eps2c');
            wd = 10; ht = 4;
            set(hF, 'paperunits', 'centimeters');
            set(hF, 'PaperPositionMode', 'manual');
            set(hF, 'papersize', [wd, ht]);
            set(hF, 'paperposition',[0, 0, wd, ht]);
            set(findall(hF, '-property', 'FontName'), 'FontName', 'Arial')
            print(hF, '-painters', '-depsc', [pathInput, '\', nameNeuron, '.eps']);
            close(hF);
        end
        hold off;
        
        
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function replot(~, ~)
        val = get(hPopupNorm, 'Value');
        if val == 1
            nm.modeNormalization = 'bottom';
        elseif val == 2
            nm.modeNormalization = 'normalize';
        else
            nm.modeNormalization = 'none';
        end

        nm.getStats;
        
        plotNeurons;
        set(findall(hFig, '-property', 'FontSize'), 'FontSize', sizeFont);
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Scroll by the slider
    function scrollBySlider(~, ~)

        % slider value
        valSlider = get(jScrollBar, 'Value');
        
        % update panel position
        movePanel(panelCurrent, valSlider);
        
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function scrollByWheel(~, event)
        
        % Get the wheel count
        valW = event.VerticalScrollCount;

        % Get slider's current position
        valS = get(jScrollBar, 'Value');
        
        valW = valW * 8; % Wheel scroll speed
        newPos = valS + valW;
        
        % Make sure position stays within acceptable range
        if newPos > sliderMax
            newPos = sliderMax;
        elseif newPos < 0
            newPos = 0;
        end
        
        % Move the slider knob
        set(jScrollBar, 'Value', newPos);

    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function movePanel(pn, pos)

        % Move panel position
        p = get(hPanelNeurons(pn), 'Position');  % panel's current position
        heightPanel = p(4);
        % Conversion factor between slider value and panel position in pixels
        factor = (heightPanel - heightAxis - marginV) / sizeSlide;
        set(hPanelNeurons(pn), 'Position',[p(1) (pos-sizeSlide)*factor+posLastPlot p(3) p(4)]);

    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function axisClick(h, ~)
        
        p = get(h, 'Position');
        p = p(2);
        numList = numel(get(hListN, 'String'));
        clickedPlot = numList - (p - marginV) / heightAxis;
        set(hListN, 'Value', clickedPlot);
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function toggleRadio(~, event)
        selection = get(event.NewValue, 'String');
        
        switch selection
            case 'Raw'
                set(hPanelNeurons(1), 'Visible', 'on');
                set(hPanelNeurons(2), 'Visible', 'off');
                set(hPanelNeurons(3), 'Visible', 'off');
                panelCurrent = 1;
            case 'SEM'
                set(hPanelNeurons(2), 'Visible', 'on');
                set(hPanelNeurons(1), 'Visible', 'off');
                set(hPanelNeurons(3), 'Visible', 'off');   
                panelCurrent = 2;
            case 'Mean'
                set(hPanelNeurons(3), 'Visible', 'on');
                set(hPanelNeurons(1), 'Visible', 'off');
                set(hPanelNeurons(2), 'Visible', 'off');
                panelCurrent = 3;
        end
        
        % update panel position
        scrollBySlider;
        
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function toggleWorms(obj, ~)
%         prt(char(obj.getName), ' = ', double(obj.isSelected));
        
        idWorm = str2double(char(obj.getName));
        isSelected = double(obj.isSelected);
        
        for n = 1:numNeurons
            numInd = size(hPlotRaw{n}, 1);
            for ni = 1:numInd
                if isvalid(hPlotRaw{n}(ni))
                    if idWorm == -1
                        set(hPlotRaw{n}(ni), 'Visible', 'on');
                    elseif idWorm == -2
                        set(hPlotRaw{n}(ni), 'Visible', 'off');
                    elseif sortedNeurons{n, 2}{ni, 3} == idWorm && isSelected
                        set(hPlotRaw{n}(ni), 'Visible', 'on');
                    elseif sortedNeurons{n, 2}{ni, 3} == idWorm && ~isSelected
                        set(hPlotRaw{n}(ni), 'Visible', 'off');
                    end
                end
            end
        end
        
        for jb = 1:numWorms+2
            if jb < 3
                jButton(jb).setSelected(false);
            else
                if idWorm == -1
                    jButton(jb).setSelected(true);
                elseif idWorm == -2
                    jButton(jb).setSelected(false);
                end
            end
        end
        
        
    end


end