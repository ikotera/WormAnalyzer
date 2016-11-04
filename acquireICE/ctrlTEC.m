function ctrlTEC()

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                               ctrlTEC.m                                 %
%                               Ver. 0.01                                 %
%                      Oct. 04, 2012 by Ippei Kotera                      %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%% Initialization

% Declare initial variables
tempIni = 18;
tempFin = 25;
tempSlope = 0.1;
holdIni = 5;
duration = 1000;
prop = .6;
integ = 4;
voltage = 4;
coolheat = 2;
enableOut = 0;
offset1 = 2.4;
offsetAt1 = 18;
offset2 = 3.4;
offsetAt2 = 28;

t = 1;
tempOven = nan(duration, 2);
tempDaq = nan(duration, 2);
setTemp = nan(duration, 2);

numFrames = 300;
currentFrame = 1;
running = 0;
hPO = nan;
hPD = nan;
hPS = nan;
namePort = 'COM4';

% Figure and axis positions
mX = 40;
mY = 100;
xDim = 500;
yDim = 300;
mag = 1;
yDim = yDim * mag;
xDim = xDim * mag;

% Initialize 5R6-900
objSer = serial(namePort, 'BaudRate', 19200);
fopen(objSer);
set(objSer, 'Terminator', {'CR','CR'});
disp([namePort, ' open.']);

% Disable output
setOutput(objSer, 0)

% Initialize DAQ
objDAQ = daq.createSession('ni');
objDAQ.addAnalogInputChannel('Dev1', 'ai0', 'Thermocouple');
objDAQ.Rate = 40;
objDAQ.DurationInSeconds = 0.05;
objTC1 = objDAQ.Channels(1);
set(objTC1)
objTC1.ThermocoupleType = 'T';
objTC1.Units = 'Celsius';

% Cleanup function
objClean = onCleanup(@()fclose(objSer));



%% Create UIcontrol Elements
% Calculate postions
updatePos;

% Create a figure with mouse wheel callback
hFig = figure('WindowScrollWheelFcn', @scrollByWheel);
set(hFig,...
    'Units', 'pixels',...
    'Toolbar', 'figure',...
    'Position', posFig,...
    'Renderer', 'Painters',...
    'DeleteFcn', {@figClose, objSer, objDAQ, namePort});

% Create axis for temperature display
hAxis = axes('Parent', hFig, 'Units', 'normalized',...
    'FontName', 'Consolas', 'FontSize', 9,....
    'Position', posAxis,...
    'Layer','top',...
    'XLim',[0 xDim],'YLim',[0 yDim]);

% % Display the file path
% hTextFilePath = uicontrol(hFig, 'Style', 'text',...
%     'String', pathDat,...
%     'BackgroundColor', get(hFig, 'Color'),...
%     'HorizontalAlignment', 'Left',...
%     'FontSize', 9,....
%     'Position', posTextFilePath);

% Create a slider control
hSlider = uicontrol(hFig, 'Style', 'slider',...
    'Units', 'normalized',...
    'Position', posSlider,...
    'SliderStep', [0.001 .01]);

%% Ramp Controls

% Create a uipanel for ramp controls
hPanelRamp = uipanel('Title', 'Ramp',...
    'FontName', 'Consolas', 'FontSize', 9,....
    'BackgroundColor', get(hFig, 'Color'),...
    'Position', posPanelRamp);

% Create a text edit for initial temperature
hEditTempIni = uicontrol('Parent', hPanelRamp, 'Style', 'edit',...
    'FontName', 'Consolas', 'FontSize', 9,....
    'Units', 'normalized',...
    'String', tempIni,...
    'Position', posEditTempIni);
hTextTempIni = uicontrol('Parent', hPanelRamp, 'Style', 'text',...
    'FontName', 'Consolas', 'FontSize', 9,....
    'Units', 'normalized',...
    'String', 'Initial Temperature',...
    'BackgroundColor', get(hFig, 'Color'),...
    'Position', posTextTempIni);

% Create a text edit for final temerature
hEditTempFin = uicontrol('Parent', hPanelRamp, 'Style', 'edit',...
    'FontName', 'Consolas', 'FontSize', 9,....
    'Units', 'normalized',...
    'String', tempFin,...
    'Position', posEditTempFin);
hTextTempFin = uicontrol('Parent', hPanelRamp, 'Style', 'text',...
    'FontName', 'Consolas', 'FontSize', 9,....
    'Units', 'normalized',...
    'String', 'Final Temperature',...
    'BackgroundColor', get(hFig, 'Color'),...
    'Position', posTextTempFin);

% Create a text edit for temperatue slope
hEditTempSlope = uicontrol('Parent', hPanelRamp, 'Style', 'edit',...
    'FontName', 'Consolas', 'FontSize', 9,....
    'Units', 'normalized',...
    'String', tempSlope,...
    'Position', posEditTempSlope);
hTextTempSlope = uicontrol('Parent', hPanelRamp, 'Style', 'text',...
    'FontName', 'Consolas', 'FontSize', 9,....
    'Units', 'normalized',...
    'String', 'dT/dt',...
    'BackgroundColor', get(hFig, 'Color'),...
    'Position', posTextTempSlope);

% Create a text edit for initial hold
hEditHoldIni = uicontrol('Parent', hPanelRamp,'Style', 'edit',...
    'FontName', 'Consolas', 'FontSize', 9,....
    'Units', 'normalized',...
    'String', holdIni,...
    'Position', posEditHoldIni);
hTextHoldIni = uicontrol('Parent', hPanelRamp, 'Style', 'text',...
    'FontName', 'Consolas', 'FontSize', 9,....
    'Units', 'normalized',...
    'String', 'Initial Hold',...
    'BackgroundColor', get(hFig, 'Color'),...
    'Position', posTextHoldIni);

% Create a text edit for duration
hEditDuration = uicontrol('Parent', hPanelRamp,'Style', 'edit',...
    'FontName', 'Consolas', 'FontSize', 9,....
    'Units', 'normalized',...
    'String', duration,...
    'Position', posEditDuration);
hTextDuration = uicontrol('Parent', hPanelRamp, 'Style', 'text',...
    'FontName', 'Consolas', 'FontSize', 9,....
    'Units', 'normalized',...
    'String', 'Duration',...
    'BackgroundColor', get(hFig, 'Color'),...
    'Position', posTextDuration);

% Create a pushbutton for starting the temperature ramp
hPushStart = uicontrol('Parent', hPanelRamp, 'Style', 'pushbutton',...
    'FontName', 'Consolas', 'FontSize', 9,....
    'Units', 'normalized',...
    'String', 'Start',...
    'Position', posPushStart,...
    'Callback', @startRamp);



%% Tuning Controls

% Create a uipanel for tuning controls
hPanelTuning = uipanel('Title', 'Tuning',...
    'FontName', 'Consolas', 'FontSize', 9,....
    'BackgroundColor', get(hFig, 'Color'),...
    'Position', posPanelTuning);

% Create a text edit for proportional bandwidth
hEditProp = uicontrol('Parent', hPanelTuning, 'Style','edit',...
    'FontName', 'Consolas', 'FontSize', 9,....
    'Units', 'normalized',...
    'String', prop,...
    'Position', posEditProp);
hTextProp = uicontrol('Parent', hPanelTuning, 'Style', 'text',...
    'FontName', 'Consolas', 'FontSize', 9,....
    'Units', 'normalized',...
    'String', 'Proportional',...
    'BackgroundColor', get(hFig, 'Color'),...
    'Position', posTextProp);

% Create a text edit for integral gain
hEditInteg = uicontrol('Parent', hPanelTuning, 'Style','edit',...
    'FontName', 'Consolas', 'FontSize', 9,....
    'Units', 'normalized',...
    'String', integ,...
    'Position', posEditInteg);
hTextInteg = uicontrol('Parent', hPanelTuning, 'Style', 'text',...
    'FontName', 'Consolas', 'FontSize', 9,....
    'Units', 'normalized',...
    'String', 'Integral',...
    'BackgroundColor', get(hFig, 'Color'),...
    'Position', posTextInteg);

% Create a text edit for votage setting
hEditVoltage = uicontrol('Parent', hPanelTuning, 'Style','edit',...
    'FontName', 'Consolas', 'FontSize', 9,....
    'Units', 'normalized',...
    'String', voltage,...
    'Position', posEditVoltage);
hTextVoltage = uicontrol('Parent', hPanelTuning, 'Style', 'text',...
    'FontName', 'Consolas', 'FontSize', 9,....
    'Units', 'normalized',...
    'String', 'Voltage',...
    'BackgroundColor', get(hFig, 'Color'),...
    'Position', posTextVoltage);

% Create a pulldown menu for cool/heat selection
hPopupCoolHeat = uicontrol('Parent', hPanelTuning, 'Style','popup',...
    'FontName', 'Consolas', 'FontSize', 9,....
    'Units', 'normalized',...
    'String', 'cool|heat',...
    'Value', coolheat,...
    'Position', posPopupCoolHeat);

% Create a checkbox for output enabling
hCheckEnableOut = uicontrol('Parent', hPanelTuning, 'Style','checkbox',...
    'Units', 'normalized',...
    'Value', enableOut,...
    'Position', posCheckEnableOut,...
    'BackgroundColor', get(hFig, 'Color'),...
    'Callback', @sendOutput);
hTextEnableOut = uicontrol('Parent', hPanelTuning, 'Style', 'text',...
    'FontName', 'Consolas', 'FontSize', 9,....
    'Units', 'normalized',...
    'String', 'Output',...
    'BackgroundColor', get(hFig, 'Color'),...
    'Position', posTextEnableOut);

% Create a pushbutton for sending values to the box
hPushSend = uicontrol('Parent', hPanelTuning, 'Style', 'pushbutton',...
    'FontName', 'Consolas', 'FontSize', 9,....
    'Units', 'normalized',...
    'String', 'Send',...
    'Position', posPushSend,...
    'Callback', @sendTuningValues);


%% Calibration Controls

% Create a uipanel for calibration controls
hPanelCalibration = uipanel('Title', 'Calibration',...
    'FontName', 'Consolas', 'FontSize', 9,....
    'BackgroundColor', get(hFig, 'Color'),...
    'Position', posPanelCalibration);

% Create a text edit for offset1
hEditOffset1 = uicontrol('Parent', hPanelCalibration, 'Style','edit',...
    'FontName', 'Consolas', 'FontSize', 9,....
    'Units', 'normalized',...
    'String', offset1,...
    'Position', posEditOffset1);
hTextOffset1 = uicontrol('Parent', hPanelCalibration, 'Style', 'text',...
    'FontName', 'Consolas', 'FontSize', 9,....
    'Units', 'normalized',...
    'String', 'Offset 1',...
    'BackgroundColor', get(hFig, 'Color'),...
    'Position', posTextOffset1);

% Create a text edit for offset2
hEditOffset2 = uicontrol('Parent', hPanelCalibration, 'Style','edit',...
    'FontName', 'Consolas', 'FontSize', 9,....
    'Units', 'normalized',...
    'String', offset2,...
    'Position', posEditOffset2);
hTextOffset2 = uicontrol('Parent', hPanelCalibration, 'Style', 'text',...
    'FontName', 'Consolas', 'FontSize', 9,....
    'Units', 'normalized',...
    'String', 'Offset 2',...
    'BackgroundColor', get(hFig, 'Color'),...
    'Position', posTextOffset2);

% Create a text edit for offsetAt1
hEditOffsetAt1 = uicontrol('Parent', hPanelCalibration, 'Style','edit',...
    'FontName', 'Consolas', 'FontSize', 9,....
    'Units', 'normalized',...
    'String', offsetAt1,...
    'Position', posEditOffsetAt1);
hTextOffsetAt1 = uicontrol('Parent', hPanelCalibration, 'Style', 'text',...
    'FontName', 'Consolas', 'FontSize', 9,....
    'Units', 'normalized',...
    'String', '@',...
    'BackgroundColor', get(hFig, 'Color'),...
    'Position', posTextOffsetAt1);

% Create a text edit for offsetAt2
hEditOffsetAt2 = uicontrol('Parent', hPanelCalibration, 'Style','edit',...
    'FontName', 'Consolas', 'FontSize', 9,....
    'Units', 'normalized',...
    'String', offsetAt2,...
    'Position', posEditOffsetAt2);
hTextOffsetAt2 = uicontrol('Parent', hPanelCalibration, 'Style', 'text',...
    'FontName', 'Consolas', 'FontSize', 9,....
    'Units', 'normalized',...
    'String', '@',...
    'BackgroundColor', get(hFig, 'Color'),...
    'Position', posTextOffsetAt2);

% Create a pushbutton for sending calibration values to the box
hPushSendCalibration = uicontrol('Parent', hPanelCalibration, 'Style', 'pushbutton',...
    'FontName', 'Consolas', 'FontSize', 9,....
    'Units', 'normalized',...
    'String', 'Send',...
    'Position', posPushSendCalibration,...
    'Callback', @sendCalibrationValues);


%% Indicators

% Create a uipanel for calibration controls
hPanelIndicators = uipanel('Title', 'Indicators',...
    'FontName', 'Consolas', 'FontSize', 9,....
    'BackgroundColor', get(hFig, 'Color'),...
    'Position', posPanelIndicators);


updateIndicators(t);

% Create jLabel Java objects for labeling with Greek symbols
for l = 1:6
    jLabel(l) = javaObjectEDT('javax.swing.JLabel', indicators{l, 1});
    bgcolor = num2cell(get(hFig, 'Color'));
    jLabel(l).setBackground(java.awt.Color(bgcolor{:}));
    [~, hcontainer(l)] = javacomponent(jLabel(l), posJ(l, :), hPanelIndicators);
    set(hcontainer(l), 'Units', 'normalized')
end



%% Java Components

% Find Java components of the slider (Requires external findjobj.m)
jScrollBar = findjobj(hSlider);
set(jScrollBar, 'AdjustmentValueChangedCallback', @scrollBySlider);
set(jScrollBar,...
    'maximum', (numFrames + 10) * 1000,...
    'minimum', 1 * 1000,...
    'unitIncrement', 1000,...
    'blockIncrement', 10000);


%% Nested Callback Functions
% Nested Function for Wheel Scroll
    function scrollByWheel(~, event)
        
        % Get a scroll count of the wheel movement
        val = event.VerticalScrollCount;
        currentFrame = currentFrame + round(val);
        
        % Make sure frame number stays within the range
        if(currentFrame > numFrames)
            currentFrame = numFrames;
        elseif(currentFrame < 1)
            currentFrame = 1;
        end
        
        % Move the slider
        set(jScrollBar, 'Value', currentFrame * 1000);
%         
%         % Display the current image
%         displayAll;
        
    end

% Nested Function for Slider
    function scrollBySlider(~,~)
        
%         % Get the slider value
%         val1 = get(jScrollBar,'Value');
%         currentFrame = round(val1 / 1000);
%         
%         % Make sure frame number stays within the range
%         if(currentFrame > numFrames)
%             currentFrame = numFrames;
%         end
%         
%         % Display the current image
%         displayAll;
        
    end




% Nested Function for holdIni Edit
    function startRamp(~, ~)
        if running == 0
            set(hPushStart, 'String', 'Stop');
            running = 1;
            % Delete the previous plots if exist
            if ~isnan(hPO)
                delete(hPO);
                hPO = nan;
            end
            if ~isnan(hPD)
                delete(hPD);
                hPD = nan;
            end
            if ~isnan(hPS)
                delete(hPS);
                hPS = nan;
            end
        elseif running == 1
            set(hPushStart, 'String', 'Start');
            running = 0;
        end
        
        % Settin initial values for temperature ramp
        t = 1;
        tPrev = nan;
        duration = 1000;
        tempOven = nan(duration, 2);
        tempDaq = nan(duration, 2);
        setTemp = nan(duration, 2);

        
        % Get ramp values from uicontrols
        getRampValues();

        sendTuningValues();
        
        tStart = tic;
        while running
            
            % Initial hold
            if toc(tStart) < holdIni

                
                setTemperature(objSer, tempIni,...
                    offset1, offsetAt1, offset2, offsetAt2);
                setTemp(t, 2) = toc(tStart);
                setTemp(t, 1) = tempIni;
            
            
            % Temperature ramp
            elseif toc(tStart) >= holdIni && setTemp(t - 1, 1) < tempFin
                % Get tPrev if it's for the first time
                if isnan(tPrev)
                    tPrev = toc(tStart);
                end
                % Increase the temperature according to the temperature
                % slope and the elapsed time since last increase
                setTemp(t, 1) = setTemp(t - 1, 1)...
                    + (tempSlope * (toc(tStart) - tPrev));
                tPrev = toc(tStart);
                setTemperature(objSer, setTemp(t, 1),...
                    offset1, offsetAt1, offset2, offsetAt2);
                setTemp(t, 2) = toc(tStart);

                
            % Final hold    
            elseif toc(tStart) >= holdIni && setTemp(t - 1, 1) >= tempFin
                setTemp(t, 1) = setTemp(t - 1, 1);
                setTemp(t, 2) = toc(tStart);
            end
            
            % Get current times and temperatures
            tempOven(t, 2) = toc(tStart);
            tempOven(t, 1) = readTemperature(objSer,...
                    offset1, offsetAt1, offset2, offsetAt2);
            tempDaq(t, 2) = toc(tStart);
            tempDaq(t, 1) = readDaq(objDAQ);
            
            t = t + 1;
            
            % Plot three temperatures
            hold on;
            if ~isnan(hPO)
                delete(hPO);
            end
            hPO = plot(hAxis, tempOven(:, 2), tempOven(:, 1), 'Color', 'red');
            
            if ~isnan(hPD)
                delete(hPD);
            end
            hPD = plot(hAxis, tempDaq(:, 2), tempDaq(:, 1));
            
            if ~isnan(hPS)
                delete(hPS);
            end
            hPS = plot(hAxis, setTemp(:, 2), setTemp(:, 1), 'Color', 'green');          
            
            ylim('auto');xlim('auto');

            % Set text strings for jLabel Java object
            updateIndicators(t - 1);
            for g = 1:6
                jLabel(g).setText(indicators{g, 1});
            end
            
            
            if t > duration
                break;
            end
            
        end
        
    end

    function getRampValues()
        
        % Get values from edit controls
        tempIni = str2double(get(hEditTempIni, 'String'));
        tempFin = str2double(get(hEditTempFin, 'String'));
        tempSlope = str2double(get(hEditTempSlope, 'String'));
        holdIni = str2double(get(hEditHoldIni, 'String'));
        duration = str2double(get(hEditDuration, 'String'));

    end

    function sendTuningValues(~, ~)
        
        prop = str2double(get(hEditProp, 'String'));
        integ = str2double(get(hEditInteg, 'String'));
        voltage = str2double(get(hEditVoltage, 'String'));
        coolheat = get(hPopupCoolHeat, 'Value');        
 
        setProportional(objSer, prop);
        setIntegral(objSer, integ);
        setVoltage(objSer, voltage);
        
        switch coolheat
            case 1
                setCoolHeat(objSer, 'cool');
            case 2
                setCoolHeat(objSer, 'heat');
        end
    end

    function sendCalibrationValues(~, ~)
        
        offset1 = str2double(get(hEditOffset1, 'String'));
        offsetAt1 = str2double(get(hEditOffsetAt1, 'String'));
        offset2 = str2double(get(hEditOffset2, 'String'));
        offsetAt2 = str2double(get(hEditOffsetAt2, 'String'));
    end

    function sendOutput(~, ~)
        
        enableOut = get(hCheckEnableOut, 'Value');
        setOutput(objSer, enableOut);
    end
        
    function updateIndicators(ft)
        
        o = readOutput(objSer);
        v = readVoltage(objSer);
        
        % Update text strings of the indicators
        t1 = '<html><pre><font face="Consolas">';
        t2 = '</font></pre></html>';
        
        indicators{1, 1} = [t1, 'TempDAQ:  ', num2str(tempDaq(ft, 1), '%04.2f'), ' &#8451;', t2];
        indicators{2, 1} = [t1, 'TempOven: ', num2str(tempOven(ft, 1), '%04.2f'), ' &#8451;', t2];
        indicators{3, 1} = [t1, 'TempSet:  ', num2str(setTemp(ft, 1), '%04.2f'), ' &#8451;', t2];
        indicators{4, 1} = [t1, 'ElpsTime: ', num2str(setTemp(ft, 2), '%06.2f'), ' s', t2];
        indicators{5, 1} = [t1, 'Voltage:  ', num2str(v), ' V', t2];
        indicators{6, 1} = [t1, 'Output:   ', num2str(o), ' %', t2];
        posJ(1, :) = [10,140,130,20];
        posJ(2, :) = [10,115,130,20];
        posJ(3, :) = [10,90,130,20];
        posJ(4, :) = [10,65,130,20];
        posJ(5, :) = [10,40,130,20];
        posJ(6, :) = [10,15,130,20];
        

    end
%% Position Data for UIcontrol Elements
% Nested Function for Position Data Update
    function updatePos
        mL1 = .05;
        mL2 = .55;
        dX = .42;
        dYE = .15;
        dYT = .1;
        
        % Positions of uicontrol elements
        posFig              = [100 100 xDim + 390 yDim + 140];
        posAxis             = [.24 .15 .50 .82];
%         posTextFilePath         = [mX mY + yDim + 30 500 25];
        posSlider           = [.24 .05 .50 .05];
        
        % Ramp controls
        posPanelRamp        = [.76 .667 .23 .323];
        
        posTextTempIni      = [mL1 .875 dX dYT];        
        posEditTempIni      = [mL1 .725 dX dYE]; 
        posTextTempFin      = [mL1 .575 dX dYT]; 
        posEditTempFin      = [mL1 .425 dX dYE]; 
        posTextTempSlope    = [mL1 .275 dX dYT]; 
        posEditTempSlope    = [mL1 .125 dX dYE]; 

        posTextHoldIni      = [mL2 .875 dX dYT];      
        posEditHoldIni      = [mL2 .725 dX dYE];   
        posTextDuration     = [mL2 .575 dX dYT];   
        posEditDuration     = [mL2 .425 dX dYE];   
        posPushStart        = [mL2 .125 dX dYE];   

        
        % Tuning controls
        posPanelTuning      = [.76 .338 .23 .323];
        
        posTextProp         = [mL1 .875 dX dYT];        
        posEditProp         = [mL1 .725 dX dYE];
        posTextInteg        = [mL1 .575 dX dYT];   
        posEditInteg        = [mL1 .425 dX dYE];
        posTextVoltage      = [mL1 .275 dX dYT];        
        posEditVoltage      = [mL1 .125 dX dYE];
        
        posPopupCoolHeat    = [mL2 .725 dX dYE]; 
        posTextEnableOut    = [mL2 + .1 .44 .23 dYT]; 
        posCheckEnableOut   = [mL2 .425 dX dYE]; 
        posPushSend         = [mL2 .125 dX dYE]; 
        
        
        % Calibration controls
        posPanelCalibration = [.76 .01 .23 .323];
        
        posTextOffset1      = [mL1 .875 dX dYT];        
        posEditOffset1      = [mL1 .725 dX dYE]; 
        posTextOffset2      = [mL1 .575 dX dYT];    
        posEditOffset2      = [mL1 .425 dX dYE]; 
        
        posTextOffsetAt1    = [.49 .739 .04 dYT];        
        posEditOffsetAt1    = [mL2 .725 dX dYE];
        posTextOffsetAt2    = [.49 .439 .04 dYT];  
        posEditOffsetAt2    = [mL2 .425 dX dYE];
        posPushSendCalibration = [mL2 .125 dX dYE]; 
        
        % Indicators
        posPanelIndicators = [.01 .59 .18 .4];
        
    end




end

function figClose(~, ~, objSer, objDAQ, namePort)

    % Disable output
    setOutput(objSer, 0)
    
    % Close serial port
    fclose(objSer);
    
    % Release DAQ
    objDAQ.release;
    
    disp([namePort, ' and DAQ closed.']);
end
