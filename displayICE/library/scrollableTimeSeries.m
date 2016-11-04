function handles = scrollableTimeSeries(handles, sVar, ND, neurons, dimZ, small, flgGUI)

if ~sum( cellfun(@numel, neurons) ) % Number of all neurons
    prt('No neurons to plot');
    return
end

progressBar(flgGUI, handles, 'initiate', 'Plotting Time Series...');

%---------------------------------------------------------------------------------------------------
% Initial variables

names = readNeurons(neurons, 'name');
timeSeries = readNeurons(neurons, 'int_ratio');

if issafe('handles.jScrollBarZ') || dimZ ~= 1
    currentZ = get(handles.jScrollBarZ, 'Value');
else
    currentZ = 1;
end

% Get Windows' Taskbar dimension
sizeWin = getSizeWindows;


widthFig = 600;
if small
    heightFig = 900;
else
    heightFig = sizeWin.bounds.height - 100;
%     heightFig = 2000;
end
widthAxis = widthFig;
heightAxis = 180;
sliderMax = 800;
sliderKnob = 100;
sizeSlide = sliderMax - sliderKnob;
marginV = 60;
marginH = 40;
posLastPlot = (heightFig - heightAxis - marginV) - 180; % Distance for the last plot to move to top
heightDown = nan;
hPanelUp = nan;
hPanelDown = nan;

%---------------------------------------------------------------------------------------------------
% Main

unitsOrigin = get(handles.fig, 'Units');
set(handles.fig, 'Units', 'pixels');
posParent = get(handles.fig, 'Position');
posX = posParent(1) + posParent(3) + 18;
set(handles.fig, 'Units', unitsOrigin);
if ishandle(handles.figTS)
else
    handles.figTS = figure('Menubar','figure', 'Resize','off', 'Name',...
        ['Calcium Dynamics: Plane = ', num2str(currentZ)],...
        'Numbertitle', 'off', 'Units','pixels', 'Position',[posX 40 widthFig+marginH*2 heightFig],...
        'WindowScrollWheelFcn', @scrollByWheel);
end

createPanelsAndPlots;

createSlider;

createPlotTemperatures;

progressBar(flgGUI, handles, 'terminate', 'Finished Plotting');

handles.jFig.getAxisComponent.requestFocus;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function createPanelsAndPlots
        
        % Create panels and plot neuronal activities
        hPanelUp = uipanel('Parent', handles.figTS, ...
            'Units','pixel', 'Position',[0, heightFig - heightAxis - marginV / 2,...
            widthAxis + marginH * 2, heightAxis + marginV]);
        hPanelDown = uipanel('Parent', handles.figTS, ...
            'Units','pixel', 'Position',[0, 0, widthAxis + marginH * 2,...
            heightFig - heightAxis - marginV / 2]);
        
        heightDown = get(hPanelDown, 'Position');
        heightDown = heightDown(4);
        handles.axesPlots = cell(dimZ, 1);
        
        for dz = 1:dimZ
            % Create a panel with axis dimension times numPlot plus margins
            numPlot = numel(timeSeries{dz});
            handles.panelNeurons(dz) = uipanel('Parent', hPanelDown, ...
                'Units','pixels', 'Visible', 'on',...
                'Position', [0, 0, widthAxis + marginH * 2, heightAxis * numPlot + marginV]);
            
            % add and plot to axes one-by-one
            handles.axesPlots{dz} = zeros(numPlot, 1);
            clr = lines(numPlot);
            
            % Create plots on the panel
            for nn = 1:numPlot
                handles.axesPlots{dz}(nn) = axes('Parent', handles.panelNeurons(dz), ...
                    'Units', 'pixel',...
                    'Position', [marginH heightAxis*(numPlot-nn)+marginV widthAxis heightAxis-marginV]...
                    );
                plot(handles.axesPlots{dz}(nn), ND{dz}(1:length(timeSeries{dz}{nn}), 4), timeSeries{dz}{nn},...
                    'LineWidth',2, 'Color', clr(nn,:));
                xlim(handles.axesPlots{dz}(nn), [min( sVar.infoND(:, 4) ), max( sVar.infoND(:, 4) )]);
                maxInt = max(timeSeries{dz}{nn});
                minInt = min(timeSeries{dz}{nn});
                dInt = maxInt - minInt;
                if isnan(dInt) || maxInt == minInt
                    continue
                end
                ylim(handles.axesPlots{dz}(nn), [minInt - dInt/20 maxInt + dInt/20]);
                set(handles.axesPlots{dz}(nn), 'ButtonDownFcn', @axisClick); % Call this after plot
                names{dz}{nn} = strrep(names{dz}{nn}, 'ON', '^{ON}');
                names{dz}{nn} = strrep(names{dz}{nn}, 'OFF', '^{OFF}');
                title(handles.axesPlots{dz}(nn), names{dz}{nn})
            end
            movePanel(dz, 1);
            progressBar(flgGUI, handles, 'iterate', [], dz, dimZ);
            
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function createSlider
        
        % Create JScrollBar object
        handles.jscrollbar = javax.swing.JScrollBar();
        handles.jscrollbar.setOrientation(handles.jscrollbar.VERTICAL);
        handles.jscrollbar.setVisibleAmount(sliderKnob);
        % Display the scroll bar
        [handles.jScrollBarTS, hSld] = javacomponent(handles.jscrollbar,...
            [widthFig+marginH*2-20 0 20 heightFig], hPanelDown);
        set(hSld, 'Units', 'pixels', 'Position', [widthFig+marginH*2-20 0 20 heightDown]);
        set(handles.jScrollBarTS, 'AdjustmentValueChangedCallback', {@scrollBySlider},...
            'maximum', sliderMax,...
            'minimum', 0,...
            'unitIncrement', 1,...
            'blockIncrement', 5);
        
        if dimZ == 1
            curZ = dimZ;
        else
            curZ = get(handles.jScrollBarZ, 'Value');
        end
        set(handles.panelNeurons(curZ), 'Visible', 'on');
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function createPlotTemperatures
        
        % Plot temperatures
        handles.axisTemp = axes('Parent', hPanelUp, 'Units','pixel',...
            'Position', [marginH marginV widthAxis heightAxis-marginV]);
        
        switch sVar.modeHeater
            case 'TEC'
                handles.axisTemp = plotTemperatures(sVar, handles.axisTemp);
            case 'zap'
                [amplitude, time] = parseZapPlan(sVar.planLaser, sVar.zapPower,...
                    sVar.duration, sVar.zapDuration);
                if max(amplitude) == 0
                    ampMax = 1;
                else
                    ampMax = max(amplitude);
                end
                plot(handles.axisTemp, time, amplitude);
                xlim(handles.axisTemp, [min( sVar.infoND(:, 4) ), max( sVar.infoND(:, 4) )]);
                ylim(handles.axisTemp, [0 - ampMax * 0.1, ampMax * 1.1]);
                title(handles.axisTemp, sprintf('Laser Stimuli'));
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function scrollBySlider(~, ~)
        
        if dimZ == 1
            valZ = dimZ;
        else
            % Get the z-value from displayICE GUI
            valZ = get(handles.jScrollBarZ, 'Value');
        end
        
        % slider value
        valSlider = get(handles.jScrollBarTS, 'Value');

        % update panel position
        movePanel(valZ, valSlider);
        
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function scrollByWheel(~, event)
        
        % Get the wheel count
        valW = event.VerticalScrollCount;

        % Get slider's current position
        valS = get(handles.jScrollBarTS, 'Value');
        
        valW = valW * 3; % Wheel scroll speed
        newPos = valS + valW;
        
        % Make sure position stays within acceptable range
        if newPos > sliderMax
            newPos = sliderMax;
        elseif newPos < 0
            newPos = 0;
        end
        
        % Move the slider knob
        set(handles.jScrollBarTS, 'Value', newPos);

    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function movePanel(z, pos)
        
        % Move panel position
        p = get(handles.panelNeurons(z), 'Position');  % panel's current position
        heightPanel = p(4);
        % Conversion factor between slider value and panel position in pixels
        factor = (heightPanel - heightAxis - marginV) / sizeSlide;
        set(handles.panelNeurons(z), 'Position',[p(1) (pos-sizeSlide)*factor+posLastPlot p(3) p(4)]);
        
%         disp([num2str(pos), ' ', num2str((pos-sizeSlide)*factor+posLastPlot)]);
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function axisClick(h, ~)
        
        p = get(h, 'Position');
        p = p(2);
        numList = numel(get(handles.listN, 'String'));
        clickedPlot = numList - (p - marginV) / heightAxis;
        set(handles.listN, 'Value', clickedPlot);
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

end