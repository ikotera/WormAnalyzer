function behaviorICE(modeApp)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                         behaviorICE.m                               
                                          Ver = '0.01';
%                                 Oct. 31, 2014 by Ippei Kotera                      
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Version History
%
% Ver. 0.01: Oct. 31, 2014; First Release.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
zero = 0; % Popular functions
if zero
    updateImages; %#ok<UNRCH>
    updateVariablesForSelectedModes;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Initial Variables
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initial mode variables
modeAcquisition = 'burst';
modeHeating = 'ramp';
modeHeater = 'IR';

flgTimer = true;
flgRepeat = false;
flgProfile = false;
% flgVerticalDisplay = true;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Static variables

% By 0.003 TC when Coolant temp is 14oC with 60xNA1.2 WI obj
offsetLowLow    =    -3; tempLowLow      =  22.0;
offsetHighLow   =   7.0; tempHighLow     =  24.0;
offsetLowHigh   = -21.4; tempLowHigh     =  22.0;
offsetHighHigh  = -13.5; tempHighHigh    =  24.0;

pathFolder = 'R:\Ippei\working\';

% % Ziegler-Nichols
% Ku = 1.34, prop bandwidth at which oscillations are constant
% Pu = 12, oscillation period in seconds
% P = Ku * 1.7
% T = Pu / 2
% D = Pu / 8

sProp = 1.28;
sInteg = 6;
sDeriv = 1.5;

sVoltage = 12;
sCoolheat = 3; % H-Bridge
sOutput = 1;
offsetDaq = -0.2;

frameZ = 1;
baseZ = 0;
dimZ = nan;
stepZ = nan;

% modeExcitation = 'LED';
modeLoop = 'startWalk';
modeCamera = 'standby';

% Figure font
sizeFont = 9;
nameFont = 'Meiryo UI';

switch modeApp
    case {'imaging', 'imagingNoTemp'}
        mmc = evalin('base', 'mmc');
        cm = mmc.getCameraDevice();
        if isempty( char(cm) )
            mmc.loadSystemConfiguration('C:\Micro-Manager-1.4\MMConfig_PCO.cfg');
        end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Dynamic variables 

% For images
% hImg(1) = nan; hImgAlignment = nan; 
nameFileICE = {'1.tiff'; '2.tiff'};
jF = []; jLabel = [];
depthBit = 8;
dimX = []; dimY = []; dimXRaw = []; dimYRaw = []; maxInt = [];
posY1 = [];posY2 = []; posX1 = [];posX2 = []; posYDisp1 = []; posYDisp2 = [];

% For experiment title
titleExperiment = []; nameSample = []; tempCultivation = []; lensObjective = []; status = [];

% For temperature controls
tempIni = nan; tempFin = nan; tempSlope = nan; holdIni = nan; duration = nan;
durationPulse = nan;
smDevices = []; enableSave = false;
rTemperature = nan; rOutput = nan; rVoltage = nan; 
waitInitialPulse = nan; waitFinalPulse = nan; intervalPulse = nan; repeatPulse = nan; modulesPulse = nan;
duration = nan;
offsetLow = nan; tempLow = 23; offsetHigh = nan; tempHigh = 28; stateRapidCooling = false; 
stateCountdown = false;
planPulse = nan;
% planPulse = [0, 20, 40, 60, 80, 100;
%             23, 33, 23, 33, 23,  23;
%              1,  2,  1,  2,  1,   1];
pIdx = 1;
statePulse = false;

% For cube and IR controls
slotCurrent = 1; stateCube = [];
flgIR = false;

% For microscope controls
waitFrame = nan; exposure(1) = nan; exposure(2) = nan; dTemperature = nan; dataV = nan; dataOB = nan;
frame = 1; tFPS = 0; FPS = 0; fs = 0;
flgEndZ = true; flgCameraAlignment = false;
flgFastAcquisition = false;
flgRequestAnalysis = false; numZStack = nan;

% Miscellaneous
pathM = []; dc = []; nameFolder = []; tmr = [];

% Fig handles and positions
handles = []; pos = []; posFig = nan;

% Variables for main loop
tPrev = nan;
tStart = nan;
tCool = nan;
skipInitialHold = nan;
fidImg = nan;
normalTermination = false;
err = [];
initialImageReady = false;
flgTerminate = false;

cBuffer = 1;
smDisk = [];
sD = [];
capFPS = 8;

% nc = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Initialization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% initDaqAI;

% Create GUI components
createGUI;
associateCallbacks;
loadDynamicUIComponents;
updateVariablesFromDynamicUIComponents; % load dynamic UI components first
updateVariablesForSelectedModes;
setTrackingPlanes;

% updateOffsets;
initiateMatlabProcesses;

switch modeApp
    case {'imaging', 'noimaging'}
end

% Some dynamic variables after GUI is created
vectorImage = [];
img = []; imgL = [];
numFrames = duration * 30;
tempRepeat = tempIni - 0.05;
tempOven = nan(numFrames, 2);
tempDaq = nan(numFrames, 2);
tempObj = nan(numFrames, 2);
tempSet = nan(numFrames, 2);
infoND = nan(numFrames, 5);

tOven = tic;
while true
    if smDevices.Data(2) == 1
        sendOven(sVoltage, 'voltage');
        break
    else
        prt('Waiting for processDevicesBehavior...');
        pause(1);
    end
    if toc(tOven) > 10
        prt('Oven not ready');
        return
    end
end


% Retrieve Oven values from the shared memory
readDevices;

updateIndicators;

main;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Main Loop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function main()
        
        normalTermination = false;
        
        if flgProfile
            numProfileFrames = 1;
            modeLoop = 'startRun';
            modeCamera = 'preAcquisition';
            profile on;
        end
        
        while true
            if flgProfile
                numProfileFrames = numProfileFrames + 1;
                disp(numProfileFrames);
                if numProfileFrames > 200
                    modeLoop = 'startWalk';
                    modeCamera = 'standby';
                    profile viewer;
                end
                modeAcquisition = 'ND';
            end
            
            switch modeLoop
                
                case 'startRun'
                  %% Start Temperature Control
                  
                    status = getStatus;
                    
                    pIdx = 1;
                    setDuration;
                    getRampValues(); % Get ramp values from uicontrols
                    sendTuningValues();
                    deletePlots;
                    createPlots;
                    resetInitialVariableValues;
                    resetSharedMemory;
                    setInitialValuesForTemperatureControl;

                    modeLoop = 'run';

                case 'run' % 'run' is acquisition + temperature control, or just temperature control
                    %%
%---------------------------------------------------------------------------------------------------        
                    switch modeCamera
                        case {'acquisition', 'postAcquisition', 'standby'}
                            controlRamp; % temperture calculation only

                            getTimesAndTemperatures; % Readings from NI devices (<0.05ms)
                            if ~flgFastAcquisition || ( flgFastAcquisition && flgEndZ )
                                updatePlots;
                                readDevices; % from shared memory < 1 ms
                                updateIndicators;
                                updateOffsets;
                                changeTemperature;
                            end
                            switch modeCamera
                                case {'acquisition', 'postAcquisition'}
                                    updateImages;
                            end
                    end
%---------------------------------------------------------------------------------------------------
                    % Image contol
                    switch modeCamera
                        % No camera is used
                        case 'standby'
                            advanceFrame;
                            tStart = tic;
                        case 'preAcquisition'
                            prepareImages;
                            tStart = tic;
                        case 'postAcquisition'
                            % Stop circular buffer if in burst mode
                            switch modeAcquisition
                                case {'burst', 'discrete'}
                                    smDisk.Data.readyMaster = 0; % Stop writing to disk
                                    stopBurst;
                                    saveVariables;
                                    modeCamera = 'finalization';
                            end
                    end
%---------------------------------------------------------------------------------------------------
                    % Finalization of image acquisition
                    if toc(tStart) >= duration % if time is up
                        switch modeCamera
                            case 'acquisition'
                                toggleAcquisition; % Change it to post-acquisition
                            case 'standby' % for temperature-only mode
                                toggleTemperature; % Change it 'postStandby'
                        end
                    end
                    
                    switch modeCamera % for temperature-only mode
                        case 'postStandby'
                            if enableSave
                                saveVariables;
                            end
                            modeCamera = 'finalization';
                    end
                    
                    switch modeCamera
                        case 'finalization'
                            frame = 1;
                            smDisk.Data.frame = frame;
                            
                            % Finalize saved files, and put a flag for analysis
                            if exist('fidImg', 'var') && ~isnan(fidImg(1))
                                for f = 1:numel(fidImg)
                                    fclose(fidImg(f));
                                    
                                    if flgRequestAnalysis
                                        fi = fopen([nameFolder '\analyze_me.flg'], 'W');
                                        fclose(fi);
                                    end
                                end
                            end

                            modeLoop = 'startWalk';
                            modeCamera = 'standby';
                    end
%---------------------------------------------------------------------------------------------------                  
                    if ~flgFastAcquisition || ( flgFastAcquisition && flgEndZ )
                        drawnow;
                    end
                    
                    % Wait between frames.
                    if waitFrame
                        sleep(waitFrame);
                    end

                    if  initialImageReady && strcmp(modeCamera, 'preAcquisition')
                        modeCamera = 'acquisition'; % This has to be after countUPFrameZ
                        initialImageReady = false;
                    end

                case 'startWalk'
                    %%
                    tStart = tic;
                    modeLoop = 'walk';
                    resetInitialVariableValues;
                    
                    if ~stateRapidCooling
                        sendTemperature('initial');
                    end

                    sleep(200);
                    
                case 'walk' % 'walk' is either preview or possibility to exit to 'loopIdle'
                    %%
                    
                    switch modeCamera
                        case 'prePreview'
                            prepareImages;
                            sleep(30);
                        case 'preview'
                            updateImages;                          
                        case 'postPreview' % Post-acquisition sequence
                            updateImages;
                            % Stop circular buffer if in burst or BCECF-burst mode
                            switch modeAcquisition
                                case 'burst'
                                    stopBurst;
                                    modeCamera = 'standby';
                            end

                            if flgEndZ
                                modeCamera = 'standby';
                                % End session for camera alignment
                                if flgCameraAlignment
                                    flgCameraAlignment = false;
                                    jF.hide;
%                                     delete(handles.figAlignCameras);
                                end
                            end
                        case 'standby'
                            if flgTimer
                                prt('Standing by...');
                                normalTermination = true;
                                timerGateway;
                                return
                            else
                                if stateRapidCooling
                                    checkAndTerminateRapidCooling;
                                end
                                normalTermination = true;
                            end
                    end
                    advanceFrame;
                    if ~flgFastAcquisition || ( flgFastAcquisition && flgEndZ )
                        readDevices;
                        updateIndicators;
                        updateOffsets;
                        drawnow;
                    end
                    
                    if flgRepeat && dTemperature < tempRepeat
                        modeAcquisition = 'BCECF';
                        toggleAcquisition
                    end
                    
                    % Wait between frames. Ignore only if it's in BCECF mode && BCECF/H cube is coming next
                    if strcmp(modeAcquisition, 'BCECF') && strcmp(stateCube, 'H')
                        % Ignoring the wait ...
                    elseif waitFrame
                        sleep(waitFrame);
                    end
                    
                    if  (strcmp(modeAcquisition, 'ND') || strcmp(modeAcquisition, 'BCECF-ND')) &&...
                            ( strcmp(modeCamera, 'preview') ||...
                            strcmp(modeCamera, 'postPreview') )
                        
                        countUpFrameZ; % This has to be after the last frameZ/flgEndZ use
                    end
                    
                    if  initialImageReady && strcmp(modeCamera, 'prePreview')
                        modeCamera = 'preview'; % This has to be after countUPFrameZ
                        initialImageReady = false;
                    end
            end % switch modeLoop
            
            if flgTerminate
                break;
            end
%             monitorSM;
        end % while true
    end % function main
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Nested Callback Functions for Main Operations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function timerGateway
        % Cleanup function
        objClean = onCleanup(@()mainLoopTermination());
        
        tmr = timer('StartDelay', 0.5, 'Period', 0.2, 'ExecutionMode', 'fixedRate');
        tmr.TimerFcn = @loopIdle;
        start(tmr);
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function loopIdle(~, ~)
        
        if stateRapidCooling
            checkAndTerminateRapidCooling;
        end
        
        if ~strcmp(modeLoop, 'walk')
            try
                closeTimer;
                main;
            catch err
                prt( char(10), getReport(err) );
                throw(err);
            end
        else
            
            readDevices;
            
            changeTemperature;
            
            updateIndicators;
            
            updateOffsets;
            pause(0.01);
            
        end
        
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function prepareImages
        
        % Set correct trigger modes
        mmc.setProperty('pco_camera', 'Triggermode', 'Internal');
        mmc.setProperty('pco_camera', 'PixelRate', 'slow scan');
        mmc.clearROI();
        mmc.setProperty('pco_camera', 'TransposeCorrection', true);
        mmc.setProperty('pco_camera', 'TransposeMirrorX', true);
        mmc.setProperty('pco_camera', 'Fps Mode', 'Off');
%         mmc.setProperty('pco_camera', 'PixelType', '8bit');
%         mmc.setProperty('pco_camera', 'Fps', 10);
        
        % Somehow, exposure needs to be re-set at this point for consistent exposure setting
        setExposures;
        acquireInitialImages;
        tFPS = tic;
        
        if strcmp(modeCamera, 'preAcquisition')
            prepareImageFiles;
        end
        
        initialImageReady = true;
        
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function updateImages
        
        if strcmp(modeCamera, 'acquisition') || strcmp(modeCamera, 'postAcquisition')
            stateAcquisition = true;
        else
            stateAcquisition = false;
        end
        
        fs = 1/( toc(tFPS) );

        if fs < capFPS
            FPS = fs;
            tFPS = tic;
            switch modeAcquisition
                case 'burst'
                    recordInfo; % < 10 ms
                    retrieveImage; % 30 ms
                    overwriteCData; % 10 ms
                case 'discrete'
                    recordInfo;
                    snapImage;
                    retrieveImage;
                    overwriteCData;
            end
            
            if stateAcquisition
                saveImages(vectorImage);
            end;
            
            advanceFrame;
        else
            pause(0.003);
        end

    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function advanceFrame
        switch modeCamera
            case {'acquisition', 'postAcquisition', 'preview', 'postPreview'}
                frame = frame + 1;
            case 'standby'
                frame = frame + 1;
                sleep(30);
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function retrieveImage
        
        %         prevImage = vectorImage;
        vi = ( mmc.getImage(0) );
        
        %         if ~isempty(vectorImage)
        %             corr = xcorr( double(prevImage(100000:105000) ), double( vectorImage(100000:105000) ), 'coeff' );
        %             prt('P = ', sum(prevImage(2500000:2505000)));
        %             dif = sum(vectorImage(2500000:2505000)) - sum(prevImage(2500000:2505000));
        %             prt('d = ', dif);
        %         end
        
        if isempty(maxInt)
            maxInt = max(vi);
        end
        
        im = reshape( vi, dimYRaw, dimXRaw, 1);

        if depthBit == 8
            im = scaleImage(im, maxInt, 0);
        end
%         warning off
        imV = im(posY1:end-posY2, posX1:end-posX2); % Crop the image to 2048 * 2048
        vectorImage = imV(:); % For saving

        im(posY1, posX1:end-posX2) = 255;
        im(end-posY2, posX1:end-posX2) = 255;

        imgL= im(:, posYDisp1:end-posYDisp2)'; % For display (2560 x 1600)
%         imgL = imV(1:2:end, 1:2:end)'; % For display (1024 x 1024, half scale of saved image)
%         imgL = im(1:2:end, 1:2:end)'; % For display (1280 x 1080, half scale of the entire FOV)
        

            
%             img = im(87:4:end-36, 197:4:end-316);
%             vectorImage = vi;

        
        
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function overwriteCData
%         if flgCameraAlignment
%             set(hImgAlignment, 'CData', imgL);
            
%             tic
            jimg = im2java(imgL);
            icon = javax.swing.ImageIcon(jimg);
            jLabel.setIcon(icon);
%             toc
%         else
%             set(hImg, 'CData', img);
%         end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function acquireInitialImages
        switch modeAcquisition
            case 'burst'
                % Start sequence acquisition
                mmc.setCircularBufferMemoryFootprint(100);
                mmc.initializeCircularBuffer();
                mmc.startSequenceAcquisition('pco_camera', 100000, 0, false);
                sleep(200);
                flgEndZ = true;
            case 'discrete'
                % Snap one image and put it in the buffer
                snapImage;
                flgEndZ = true;
        end
        
        retrieveImage;
        
        %         if flgCameraAlignment
        
        jimg = im2java(imgL);
        if isjava(jF)
            jF.hide;
        end
        jF = javax.swing.JFrame;
        jF.setUndecorated(true);
        icon = javax.swing.ImageIcon(jimg);
        jLabel = javax.swing.JLabel(icon);
        jF.getContentPane.add(jLabel);
        jF.pack;
        screenSize = get(0,'ScreenSize');  %# Get the screen size from the root object
        screenSize(3) = 2560;
        screenSize(4) = 1600;
        jF.setSize(screenSize(3),screenSize(4));
        jF.setLocation(0,0);
        jF.show;

%         else
%             
%             hImg = imagesc(img(:, :), 'Parent', handles.axisImages(1));
%             colormap(gray(256));
%             set(hImg, 'EraseMode', 'none');
%             set(handles.axisImages(1), 'Units', 'pixels');
%             set(handles.axisImages(1), 'XTick', [], 'YTick', []);
%             set(handles.axisImages(1), 'xlimmode','manual',...
%                 'ylimmode','manual',...
%                 'zlimmode','manual',...
%                 'climmode','manual',...
%                 'alimmode','manual');
%         end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function prepareImageFiles
            % Format the folder name
            nameFolder = [pathFolder, datestr(now, 'yymmdd'),...
                ' ', titleExperiment, '\', datestr(now, 'yymmdd-HHMM'), '\'];
            
            % Create the folder if it doesn't exist already
            if ~exist(nameFolder, 'dir')
                mkdir(nameFolder);
            end
            
            % Save 4 files if infrared image is acquired, otherwise 2 files.
            numSaveImages = 1;
            
            for ind = 1:numSaveImages
                
                % Format names for ice files
                nameFileICE{ind} = [nameFolder,...
                    'Img-' num2str(ind), '_',...
                    datestr(now, 'yymmdd-HHMM'),...
                    '.ice'];
                % Format string header
                [~, hdrChr{ind}] = formatHeaderChar({...
                    'TimeStamp', datestr(now);...
                    'Ver', Ver;...
                    'PathFolder' pathFolder;...
                    'Experiment' titleExperiment;...
                    'ModeApp' modeApp;...
                    'ModeAcquisition' modeAcquisition;...
                    });
                hdrNum{ind}(1, 1) = dimX; %#ok<*AGROW>
                hdrNum{ind}(1, 2) = dimY;
                hdrNum{ind}(1, 3) = dimZ;
                hdrNum{ind}(1, 4) = baseZ;
                hdrNum{ind}(1, 5) = stepZ;
                hdrNum{ind}(1, 6) = depthBit; % Used to be waitStage but now bit depth of image (150313)
                hdrNum{ind}(1, 7) = sDeriv; % Changed from waitPFS
                hdrNum{ind}(1, 8) = tempIni; 
                hdrNum{ind}(1, 9) = tempFin; 
                hdrNum{ind}(1, 10) = tempSlope; 
                hdrNum{ind}(1, 11) = holdIni; 
                hdrNum{ind}(1, 12) = duration; 
                hdrNum{ind}(1, 13) = sProp; 
                hdrNum{ind}(1, 14) = sInteg; 
                hdrNum{ind}(1, 15) = sVoltage; 
                hdrNum{ind}(1, 16) = sCoolheat; 
                hdrNum{ind}(1, 17) = offsetDaq; 
                hdrNum{ind}(1, 18) = offsetLow; 
                hdrNum{ind}(1, 19) = tempLow; 
                hdrNum{ind}(1, 20) = offsetHigh; 
                hdrNum{ind}(1, 21) = tempHigh; 
                hdrNum{ind} = [hdrNum{ind}, nan(1, 256 - length(hdrNum{ind}))]; 

                smDisk.Data.headerNum = hdrNum{ind};
                writeCharInShareMemory(smDisk, 'headerChar', hdrChr{ind}, 2048);
                writeCharInShareMemory(smDisk, 'nameFile', nameFileICE{ind}, 256);
                smDisk.Data.readyMaster = 1;
                while true
                    if smDisk.Data.readySlave == 1
                        prt('Detected slave is ready.');
                        break
                    end
                    pause(0.1);
                end
                
%                 fidImg = fopen(nameFileICE{1}, 'W');
                
            end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function recordInfo
        switch modeAcquisition
            case {'discrete', 'burst'}
                infoND(frame, 1) = frame;
                infoND(frame, 2) = 1;
                infoND(frame, 3) = 0;
                infoND(frame, 4) = toc(tStart);
                infoND(frame, 5) = slotCurrent;
            otherwise
                infoND(frame, 1) = frame;
                infoND(frame, 2) = frameZ;
                infoND(frame, 3) = dataV * 10;
                infoND(frame, 4) = toc(tStart);
                infoND(frame, 5) = slotCurrent;
        end
        %         prt(frame, modeCamera, modeLoop);
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function stopBurst
        mmc.stopSequenceAcquisition('pco_camera');
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function saveImages(vector)

        if cBuffer > sD.sizeBuffer
            cBuffer = 1;
        end
%         t = tic;
        smDisk.Data.frame = frame;
        smDisk.Data.image(:, cBuffer) = vector;
%         prt('%0.4f', cBuffer, frame, toc(t) );
        
        cBuffer = cBuffer + 1;

    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function snapImage
        mmc.snapImage();
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function getRampValues()
        % Get values from edit controls
        tempIni = str2double(get(handles.editTemperatureInitial, 'String'));
        tempFin = str2double(get(handles.editTemperatureFinal, 'String'));
        tempSlope = str2double(get(handles.editSlopeTemperature, 'String'));
        holdIni = str2double(get(handles.editWaitInitialRamp, 'String'));
        duration = str2double(get(handles.editDurationRamp, 'String'));
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function updateIndicators
        
        if strcmp(modeLoop, 'run')
            da = tempDaq(frame, 1);
            ov = tempOven(frame, 1);
            st = smDevices.Data(21); % Offseted set temperature sent to Oven
            et = tempSet(frame, 2);
            ot = tempObj(frame, 1);
        else
            da = dTemperature;
            ov = rTemperature;
            ot = dataOB;
            st = tempIni - offsetTemp(tempIni, offsetLow, tempLow, offsetHigh, tempHigh);
            et = nan;
        end
        
        op = rOutput;
        vl = rVoltage;
        
        % Update text strings of the indicators
        set(handles.textTempDaq,    'String', ['TempDAQ:  ', num2str(da, '%04.2f'), ' C']);
        set(handles.textTempOven,   'String', ['TempOven: ', num2str(ov, '%04.2f'), ' C']);
        set(handles.textTempSet,    'String', ['TempSet:  ', num2str(st, '%04.2f'), ' C']);
        set(handles.textTempObj,    'String', ['TempObj:  ', num2str(ot, '%04.2f'), ' C']);
        set(handles.textElapsedTime,'String', ['ElpsTime: ', num2str(et, '%06.2f'), ' s' ]);
        set(handles.textVoltage,    'String', ['Voltage:  ', num2str(vl),           ' V' ]);
        set(handles.textOutput,     'String', ['Output:   ', num2str(op),           ' %' ]);
        set(handles.textFPS,        'String', ['FPS:      ', num2str(FPS,'%04.1f'), ''   ]);
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function sendOven(value, mode)
        
        idx = nan;
        
        % Set first byte to zero, indicating the message is not ready yet
        smDevices.Data(1) = 1; % always 'on' for now
        
        switch mode
            case 'temperature'
                idx = 21;
            case 'voltage'
                idx = 22;
            case 'output'
                idx = 23;
            case 'proportional'
                idx = 24;
            case 'integral'
                idx = 25;
            case 'coolheat'
                idx = 26;
            case 'derivative'
                idx = 27;
            otherwise
                prt('Oven mode not specified:' , mode);
        end
        
        if ~isnan(idx)
            smDevices.Data(idx) = value;
            smDevices.Data(1) = 1; % ready to parse
        end 
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function readDevices
        rTemperature = smDevices.Data(31); % temperature
        rVoltage = smDevices.Data(32); % voltage
        rOutput = smDevices.Data(33); % output
        dTemperature = smDevices.Data(41) + offsetDaq; % TC temperature from Daq
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function updateOffsets
        % Update the offset temperatures according to the ambient temperature
        offsetLow = offsetTemp(dataOB, offsetLowLow, tempLowLow, offsetHighLow, tempHighLow);
        offsetHigh = offsetTemp(dataOB, offsetLowHigh, tempLowHigh, offsetHighHigh, tempHighHigh);
        set(handles.editOffsetLow, 'String', num2str(offsetLow));
        set(handles.editOffsetHigh, 'String', num2str(offsetHigh));
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function changeTemperature
        switch modeHeating
            case 'ramp'
                if flgEndZ
                    sendTemperature('auto');
                end
            case 'pulse'
                
                
                if statePulse
                    
                    switch modeHeater
                        case 'TEC'
                            sendTemperature( 'manual', planPulse(2, pIdx-1) );
                        case 'IR'
                            toggleShutter( planPulse(2, pIdx-1) );
                            sendTemperature( 'manual', planPulse(4, pIdx-1) );
                    end
                    
                    statePulse = false;
                end
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function toggleShutter(tempPlan)
        
        if tempPlan == tempIni
            mmc.setProperty('Shutter-A', 'State', false); % IR shutter closed
        elseif tempPlan == tempFin
            mmc.setProperty('Shutter-A', 'State', true); % IR shutter open
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function sendTemperature(mode, temp)
        switch mode
            case 'auto'
                switch modeLoop
                    case 'run'
                        adjTemp = tempSet(frame, 1) -...
                            offsetTemp(tempSet(frame, 1), offsetLow, tempLow, offsetHigh, tempHigh);
                    case 'walk'
                        adjTemp = tempIni -...
                            offsetTemp(tempIni, offsetLow, tempLow, offsetHigh, tempHigh);
                    otherwise
                        prt('Temperature not sent');
                end
            case 'current'
                adjTemp = tempSet(frame, 1) -...
                    offsetTemp(tempSet(frame, 1), offsetLow, tempLow, offsetHigh, tempHigh);
            case 'initial'
                adjTemp = tempIni -...
                    offsetTemp(tempIni, offsetLow, tempLow, offsetHigh, tempHigh);
            case 'manual'
                adjTemp = temp -...
                    offsetTemp(tempIni, offsetLow, tempLow, offsetHigh, tempHigh);
            otherwise
                prt('Wrong temperature mode');
                return
        end
        
        sendOven(adjTemp, 'temperature');

    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function controlRamp
        switch modeHeating
            case 'ramp'
                % Initial hold
                if toc(tStart) < holdIni
                    tempSet(frame, 2) = toc(tStart);
                    tempSet(frame, 1) = tempIni;
                    skipInitialHold = 0;
                    % If initial hold is skipped
                elseif skipInitialHold == 1
                    tempSet(frame, 2) = toc(tStart);
                    tempSet(frame, 1) = tempIni;
                    skipInitialHold = 2;
                    
                    % Temperature ramp
                elseif toc(tStart) >= holdIni && tempSet(frame - 1, 1) < tempFin
                    % Get tPrev if it's for the first time
                    if isnan(tPrev)
                        tPrev = toc(tStart);
                    end
                    % Increase the temperature according to the temperature
                    % slope and the elapsed time since last increase
                    tempSet(frame, 1) = tempSet(frame - 1, 1)...
                        + (tempSlope * (toc(tStart) - tPrev));
                    tPrev = toc(tStart);
                    tempSet(frame, 2) = toc(tStart);
                    
                    % Final hold
                elseif toc(tStart) >= holdIni && tempSet(frame - 1, 1) >= tempFin
                    tempSet(frame, 1) = tempSet(frame - 1, 1);
                    tempSet(frame, 2) = toc(tStart);
                end
            case 'pulse'
                if size(planPulse, 2) > pIdx && toc(tStart) > planPulse(1, pIdx)
                    pIdx = pIdx + 1;
                    statePulse = true;
                else
                    statePulse = false;
                end

                tempSet(frame, 2) = toc(tStart);
                tempSet(frame, 1) = planPulse(2, pIdx-1);
%                 prt( tempSet(frame, 2), tempSet(frame, 1), pIdx-1 );
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function getTimesAndTemperatures

        % Get current times and temperatures
        tempOven(frame, 2) = toc(tStart);
        % tempOven(frame, 1) = share2mat('temperature');
        tempOven(frame, 1) = rTemperature;
        tempDaq(frame, 2) = toc(tStart);
        tempDaq(frame, 1) = dTemperature;
        tempObj(frame, 2) = toc(tStart);
        tempObj(frame, 1) = dataOB;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function createPlots   
        lw = 2;
        % Create plots for temperature readings
        handles.plotOven = line(tempOven(:, 2), tempOven(:, 1),...
            'Parent', handles.axisTemperatures, 'Color', [255, 120, 183] ./ 255,...
            'LineWidth', lw);
        handles.plotDaq = line(tempDaq(:, 2), tempDaq(:, 1),...
            'Parent', handles.axisTemperatures, 'Color', [51 255 105]./ 255,...
            'LineStyle', '-', 'LineWidth', lw);
        handles.plotSet = line(tempSet(:, 2), tempSet(:, 1),...
            'Parent', handles.axisTemperatures, 'Color', [77 225 255]./ 255,...
            'LineStyle', '-', 'LineWidth', lw);
        handles.plotObjective = line(tempObj(:, 2), tempObj(:, 1),...
            'Parent', handles.axisTemperatures, 'Color', [255 153 51]./ 255,...
            'LineStyle', '-', 'LineWidth', lw,...
            'Marker', 'none');
        
        % static limits of the plots
        switch modeHeating
            case 'ramp'
                mi = tempIni - offsetTemp(tempIni, offsetLow, tempLow, offsetHigh, tempHigh);
                ma = tempFin - offsetTemp(tempFin, offsetLow, tempLow, offsetHigh, tempHigh);
            case 'pulse'
                mi = min(planPulse(4, :) );
                ma = max(planPulse(2, :) );
        end
        
        mrg = abs(ma - mi) / 3;
        
        if mi < ma
            ylim(handles.axisTemperatures, [mi - mrg ma + mrg]);
        elseif mi > ma
            ylim(handles.axisTemperatures, [ma - mrg mi + mrg]);
        else
            ylim(handles.axisTemperatures, [mi - 2 ma + 2]);
        end
        xlim(handles.axisTemperatures, [0, duration]);
        setappdata(handles.axisTemperatures, 'LegendColorbarManualSpace', 1);
        setappdata(handles.axisTemperatures, 'LegendColorbarReclaimSpace', 1);
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function updatePlots
        % Update the plots for three temperature measurements This is THE fastest way to plot
        % numbers (use 'EraseMode', 'none' setting in the initial line function).

        set(handles.plotOven, 'XData', tempOven(:, 2), 'YData', tempOven(:, 1));
        set(handles.plotDaq, 'XData', tempDaq(:, 2), 'YData', tempDaq(:, 1));
        set(handles.plotSet, 'XData', tempSet(:, 2), 'YData', tempSet(:, 1));
        set(handles.plotObjective, 'XData', tempObj(:, 2), 'YData', tempObj(:, 1));
        
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function deletePlots
        % Delete the previous plots if exist
        if isfield(handles, 'plotOven') && ishandle(handles.plotOven)
            delete(handles.plotOven);
            handles = rmfield(handles, 'plotOven');
        end
        if isfield(handles, 'plotDaq') && ishandle(handles.plotDaq)
            delete(handles.plotDaq);
            handles = rmfield(handles, 'plotDaq');
        end
        if isfield(handles, 'plotSet') && ishandle(handles.plotSet)
            delete(handles.plotSet);
            handles = rmfield(handles, 'plotSet');
        end
        if isfield(handles, 'plotObjective') && ishandle(handles.plotObjective)
            delete(handles.plotObjective);
            handles = rmfield(handles, 'plotObjective');
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     function switchCoolHeat
%         
%         switch modeLoop
%             case 'run'
%                 st = tempSet(frame, 1) -...
%                     offsetTemp(tempSet(frame, 1), offsetLow, tempLow, offsetHigh, tempHigh);
%             case 'walk'
%                 st = tempIni - offsetTemp(tempIni, offsetLow, tempLow, offsetHigh, tempHigh);
%         end
%         
%         % TEC cool/heat switch
%         if (rTemperature > st) && rOutput == 0
%             sendOven(1, 'coolheat'); % set it to 'cool'
%             set(handles.popupCoolHeat, 'Value', 1);
%         elseif(rTemperature < st) && rOutput == 0
%             sendOven(2, 'coolheat'); % set it to 'heat'
%             set(handles.popupCoolHeat, 'Value', 2);
%         end
% 
%     end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function makePlanPulse
        
        planPulse = nan;
        
        % Initial variables
        tp = 0;
        idx = 1;
%         offsetUp = 0;
%         offsetDown1 = 0;
%         offsetDown2 = 0;
%         lenOffsetUp = 0;
%         lenOffsetDown1 = 0;
        offsetOvenHighStart = 7;
%         offsetOvenHighEnd = 14;
        offsetOvenLowStart = 17;
        offsetOvenLowEnd = 27;  % Adjust this value according to ambient heat source temperature (15-25s)
        tempOvenHigh = tempIni + 10;
        tempOvenLow = tempIni - 9;
        tempOvenNeutral = tempIni;
        
        
        
        buildPulse(tempIni, 1, waitInitialPulse - offsetOvenHighStart - 0, tempOvenNeutral); % initial wait
        buildPulse(tempIni, 1, offsetOvenHighStart + 0, tempOvenHigh);
        for rp = 1:repeatPulse
            
            %             buildPulse(tempFin + offsetUp, 2, lenOffsetUp); % virtual top
            buildPulse(tempFin, 2, durationPulse - offsetOvenLowStart, tempOvenHigh); % real top
            buildPulse(tempFin, 2, offsetOvenLowStart, tempOvenLow);
            %             buildPulse(tempIni - offsetDown1, 1, lenOffsetDown1); % virtual bottom
            buildPulse(tempIni, 1, intervalPulse - offsetOvenLowEnd, tempOvenLow); % real bottom
            buildPulse(tempIni, 1, offsetOvenLowEnd - offsetOvenHighStart, tempOvenNeutral - 0.7);
            %             buildPulse(tempIni, 1, waitFinalPulse, tempIni); % final bottom
            if rp ~= repeatPulse
                buildPulse(tempIni, 1, offsetOvenHighStart, tempOvenHigh);
            else
                buildPulse(tempIni, 1, offsetOvenHighStart, tempIni);
            end
        end
        
        buildPulse(tempIni, 1, nan, tempIni); % final time point

        duration = planPulse(1, end);
        holdIni = duration;
%---------------------------------------------------------------------------------------------------
        function buildPulse(temp, coolheat, lenEvent, tempTEC)
            planPulse(1, idx) = tp;
            planPulse(2, idx) = temp;
            planPulse(3, idx) = coolheat;
            planPulse(4, idx) = tempTEC;
            tp = tp + lenEvent;
            idx = idx + 1;
        end
%---------------------------------------------------------------------------------------------------        
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function checkAndTerminateRapidCooling
        tO = rTemperature;
        iO = tempIni - offsetTemp(tempIni, offsetLow, tempLow, offsetHigh, tempHigh);
        if iO > tO + 1
            if ~stateCountdown
                tCool = tic; % start rapid cooling termination count-down
                stateCountdown = true;
                prt('Counting down to terminate rapid cooling...');
            end
            if toc(tCool) > 1
                sendOven(sVoltage, 'voltage');
%                 sendOven(2, 'coolheat');
%                 set(handles.popupCoolHeat, 'Value', 2);
                prt('Voltage = ', sVoltage, 'V for regular control');
                stateRapidCooling = false;
                stateCountdown = false;
            end
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Nested function for saving temperature readings to mat file
    function saveVariables
        % Get rid of rows that are all NaN from the 2D matrices and save them (Vectorized)
        tempSet = tempSet(any(~isnan(tempSet), 2), :);
        tempOven = tempOven(any(~isnan(tempOven), 2), :);
        tempDaq = tempDaq(any(~isnan(tempDaq), 2), :);
        infoND = infoND(any(~isnan(infoND), 2), :);
        numFrames = frame - 1;
        status.nameSample = nameSample;
        status.lensObjective = lensObjective;
        status.tempCultivation = tempCultivation;
        status.modeAcquisition = modeAcquisition;
        status.modeHeating = modeHeating;
        status.titleExperiment = titleExperiment;

        % Save variable that are esential for analysis
        save([strrep(strrep(nameFileICE{1}, '.ice', ''), 'Img-1_', 'Variables_'), '.mat'],...
            'tempDaq', 'tempOven', 'tempSet', 'Ver',...
            'modeAcquisition', 'modeHeater', 'flgIR', ...
            'waitInitialPulse', 'waitFinalPulse',...
            'numFrames', 'planPulse', 'durationPulse', 'intervalPulse', 'repeatPulse',...
            'offsetDaq', 'pathFolder', 'titleExperiment', 'exposure', 'dimX', 'dimY', 'depthBit',...
            'tempIni', 'tempFin', 'tempSlope', 'holdIni', 'duration',...
            'sProp', 'sInteg', 'sVoltage', 'sCoolheat', 'sOutput',...
            'offsetLowLow', 'tempLowLow', 'offsetHighLow', 'tempHighLow',...
            'offsetLowHigh', 'tempLowHigh', 'offsetHighHigh', 'tempHighHigh',...
            'dimZ', 'baseZ', 'stepZ', 'waitFrame',...
            'infoND', 'status');
        
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Nested Functions for UI Callbacks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Nested callback function for push start preview
    function togglePreview(~, ~)
        % Set it to 'preview' if it's standing by
        if strcmp(modeCamera, 'standby')
            set(handles.pushPreview, 'String', 'Stop');
            set(handles.pushAcquire, 'String', 'Acquire');
            modeCamera = 'prePreview';
            modeLoop = 'startWalk';
            
        % Set it to 'postPreview' if it's previewing
        elseif strcmp(modeCamera, 'preview')
            modeCamera = 'postPreview';
            set(handles.pushPreview, 'String', 'Preview');
            set(handles.pushAcquire, 'String', 'Acquire');
            
        % Set it to 'preview' if it's acquiring
        elseif strcmp(modeCamera, 'acquisition')
            modeCamera = 'prePreview';
            set(handles.pushPreview, 'String', 'Stop');
            set(handles.pushAcquire, 'String', 'Acquire');
            modeLoop = 'startWalk';
        end
        
        handles.jFig.getAxisComponent.requestFocus;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function toggleAcquisition(~, ~)
        switch modeCamera
            % Set it to 'acquisition' if it's standing by
            case 'standby'
                modeCamera = 'preAcquisition';
                set(handles.pushPreview, 'String', 'Preview');
                set(handles.pushAcquire, 'String', 'Stop');
                set(handles.pushStartRamp, 'String', 'Stop');
                modeLoop = 'startRun';
                
            % Set it to 'postAcquisition' if it's acquiring
            case 'acquisition'
                modeCamera = 'postAcquisition';
                set(handles.pushPreview, 'String', 'Preview');
                set(handles.pushAcquire, 'String', 'Acquire');
                set(handles.pushStartRamp, 'String', 'Start');
                
            % Set it to 'acquisition' if it's previewing
            case 'preview'
                modeCamera = 'preAcquisition';
                set(handles.pushPreview, 'String', 'Preview');
                set(handles.pushAcquire, 'String', 'Stop');
                set(handles.pushStartRamp, 'String', 'Stop');
                modeLoop = 'startRun';
        end
        
        handles.jFig.getAxisComponent.requestFocus;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function toggleAlign(~, ~)

        if flgCameraAlignment
            set(handles.fig, 'Position', posFig);
            set(handles.pushAlignCameras, 'String', 'Align');
            modeCamera = 'postPreview';
            handles.jFig.getAxisComponent.requestFocus;
        elseif ~flgCameraAlignment
            posFig = get(handles.fig, 'Position');
%             set(handles.fig, 'Position', [1240 posFig(2) posFig(3) posFig(4)]);
            set(handles.pushAlignCameras, 'String', 'Stop');
            modeCamera = 'prePreview';
            modeLoop = 'startWalk';
            flgCameraAlignment = true;
            
%             % Create a figure
%             handles.figAlignCameras = figure;
%             % Alignment figure
%             xDimImage = 1575;
%             yDimImage = 1575;
%             pos.figAlignCameras     = [100 -1600 xDimImage+50 yDimImage+50];
%             pos.panelAlignCameras   = [25 25 xDimImage yDimImage];
%             pos.axisAlignCameras    = [0 0 xDimImage yDimImage];
%             set(handles.figAlignCameras, 'Units', 'pixels', 'Toolbar', 'figure',...
%                 'Name', 'Dual Camera Alignment', 'Numbertitle', 'off', 'Position',...
%                 pos.figAlignCameras, 'Renderer', 'Painters', 'CloseRequestFcn', @endAlignment);
%             
%             % Create a panel for alignment
%             handles.panelCameraAlignment = uipanel('Parent',handles.figAlignCameras, 'Units',...
%                 'pixels', 'BackgroundColor', get(handles.figAlignCameras, 'Color'), 'Position',...
%                 pos.panelAlignCameras);
%             
%             % Create axis for alignment images
%             handles.axisAlignCameras = axes('Parent', handles.panelCameraAlignment, 'Units',...
%                 'pixels', 'FontName', nameFont, 'FontSize', sizeFont, 'Position', pos.axisAlignCameras,...
%                 'Layer','top');
%             set(handles.axisAlignCameras, 'XTick', [], 'YTick', []);
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function toggleTemperature(~, ~)
        
        switch modeCamera % make sure no camera is being used
            case 'standby'
                switch modeLoop
                    case 'walk' % Set it to 'startRun' if it's walking
                        set(handles.pushStartRamp, 'String', 'Stop');
                        modeLoop = 'startRun';
                        deletePlots;
                    case 'run' % Set it to 'walk' if it's running
                        set(handles.pushStartRamp, 'String', 'Start');
                        modeCamera = 'postStandby';
                end
        end
        handles.jFig.getAxisComponent.requestFocus;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function setExposures(~, ~)
        exposure(1) = str2double(get(handles.editExposureR, 'String'));
        exposure(2) = str2double(get(handles.editExposureG, 'String'));
        
        % Java error if exposure is changed without this line
        mmc.setExposure(exposure(1));
        mmc.setProperty('pco_camera', 'Exposure', exposure(1));
        mmc.getProperty('pco_camera', 'Exposure');
        if ~flgCameraAlignment
            handles.jFig.getAxisComponent.requestFocus;
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function setFlgRequestAnalysis(~, ~)
        flgRequestAnalysis = get(handles.checkRequestAnalysis, 'Value');
        handles.jFig.getAxisComponent.requestFocus;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function setPulseVariables(~, ~)
        waitInitialPulse = str2double(get(handles.editWaitInitialLaser, 'String'));
        waitFinalPulse = str2double(get(handles.editWaitFinalLaser, 'String'));
        intervalPulse = str2double(get(handles.editIntervalLaser, 'String'));
        durationPulse = str2double(get(handles.editDurationLaser, 'String'));
        repeatPulse = str2double(get(handles.editRepeatLaser, 'String'));
        modulesPulse = str2double(get(handles.editModulesLaser, 'String'));
        
        makePlanPulse;
        makeExperimentTitle;
        updateStaticUIComponents;
        handles.jFig.getAxisComponent.requestFocus;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function setRampVariables(~, ~)
        holdIni = str2double(get(handles.editWaitInitialRamp, 'String'));
        duration = str2double(get(handles.editDurationRamp, 'String'));
        tempIni = str2double(get(handles.editTemperatureInitial, 'String'));
        tempFin = str2double(get(handles.editTemperatureFinal, 'String'));

        makeExperimentTitle;
        updateStaticUIComponents;
        handles.jFig.getAxisComponent.requestFocus;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function setPathFolder(~, ~)
        pathFolder = get(handles.editPathFolder, 'String');
        handles.jFig.getAxisComponent.requestFocus;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function setTitle(~, ~)
        titleExperiment = get(handles.editTitle, 'String');
        handles.jFig.getAxisComponent.requestFocus;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function setDuration(~, ~)
        duration = str2double(get(handles.editDurationRamp, 'String'));
        numFrames = duration * 30; % Assuming frame rate is < 30 frames/s
        
        if strcmp(modeLoop, 'walk') || strcmp(modeLoop, 'startRun')
            tempOven = nan(numFrames, 2);
            tempDaq = nan(numFrames, 2);
            tempSet = nan(numFrames, 2);
            tempObj = nan(numFrames, 2);
        end
        handles.jFig.getAxisComponent.requestFocus;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function toggleSave(~, ~)
        enableSave = get(handles.checkSaveRamp, 'Value');
        % Format the folder name
        nameFolder = [pathFolder, datestr(now, 'yymmdd'),...
            ' ', titleExperiment, '\', datestr(now, 'yymmdd-HHMM'), '\'];
        % Create the folder if it doesn't exist already
        if ~exist(nameFolder, 'var'), mkdir(nameFolder); end
        % Format names for ice files
        nameFileICE{1} = [nameFolder, 'Img-' num2str(1), '_', datestr(now, 'yymmdd-HHMM'), '.ice'];
        handles.jFig.getAxisComponent.requestFocus;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function sendTuningValues(~, ~)
        
        sProp = str2double(get(handles.editProportional, 'String'));
        sendOven(sProp, 'proportional');
        
        sInteg = str2double(get(handles.editIntegral, 'String'));
        sendOven(sInteg, 'integral');
        
        sDeriv = str2double(get(handles.editDerivative, 'String'));
        sendOven(sDeriv, 'derivative');       
        
        sVoltage = str2double(get(handles.editVoltage, 'String'));
        sendOven(sVoltage, 'voltage');
        
        sCoolheat = get(handles.popupCoolHeat, 'Value');
        sendOven(sCoolheat, 'coolheat');
        
        handles.jFig.getAxisComponent.requestFocus;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function sendObjectiveOffsets(~, ~)
        offsetLowLow = str2double(get(handles.editOffsetLowLow, 'String'));
        tempLowLow = str2double(get(handles.editTempLowLow, 'String'));
        offsetHighLow = str2double(get(handles.editOffsetHighLow, 'String'));
        tempHighLow = str2double(get(handles.editTempHighLow, 'String'));
        
        offsetLowHigh = str2double(get(handles.editOffsetLowHigh, 'String'));
        tempLowHigh = str2double(get(handles.editTempLowHigh, 'String'));
        offsetHighHigh = str2double(get(handles.editOffsetHighHigh, 'String'));
        tempHighHigh = str2double(get(handles.editTempHighHigh, 'String'));        

        handles.jFig.getAxisComponent.requestFocus;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function sendOutput(~, ~)
        sOutput = get(handles.checkEnableOut, 'Value');
        sendOven(sOutput, 'output');
        handles.jFig.getAxisComponent.requestFocus;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function mainLoopTermination(~, ~)
        
%         prt('mainLoopTermination invoked');
        if ~normalTermination
            
            flgTerminate = true;
            
            prt('Abnormal termination detected...');
            
            closeTimer;
            
            sendTemperature('initial');
            stopAndCloseEverything;
            
            if issafe('handles.fig')
                delete(handles.fig);
                prt('Figure closed');
            end
            
            if ~isempty(err)
                prt('Saving error status to base...');
                assignin('base', 'err', err);
                prt( char(10), getReport(err) );
                throw(err);
            end
            
        else
            % normal termination of main
        end
        
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function figureTermination(~, ~)
        
        prt('Figure termination in progress...');
        flgTerminate = true;
        sendTemperature('initial');
        stopAndCloseEverything;
        
        if issafe('handles.fig')
            delete(handles.fig);
            prt('Figure closed');
        end

    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function stopAndCloseEverything
        
        if issafe('mmc')
            try
                mmc.unloadDevice('pco_camera');
                prt('Unloading pco_camera...');
            catch
            end
        end
        
        if issafe('jF')
            jF.hide;
        end
        
        switch modeHeater
            case 'IR'
                mmc.setProperty('Shutter-A', 'State', false); % IR shutter closed
        end
        
        if issafe('tmr')
            stop(tmr);
        end
        
        if exist('smDisk', 'var')
            smDisk.Data.destroySlave = 1;
            prt('Closing processWriteToDisk...');
        end
        
        if exist('smDevices', 'var')
            % Stop Devices
            smDevices.Data(4) = 1;
            prt('Closing processDevicesBehavior...');
        end
        
        fclose('all'); % close all open files

        
        if ~isempty(instrfind)
            fclose(instrfind); % Close any unclosed serial ports
            delete(instrfind);
            prt('Unclosed serial closed');
        end
        
        if ~isempty(timerfindall)
        delete(timerfindall); % Close any left over timers
        prt('Unclosed timer closed');
        end
        
        
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function closeTimer
        if issafe('tmr')
            stop(tmr);
            sleep(1000);
            delete(tmr);
            clear tmr
            prt('Timer closed');
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function endAlignment(~, ~)
        toggleAlign;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Nested Functions for Initializations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function initiateMatlabProcesses
        
        % Delete memmap files from previous sessions
        delete( fullfile(tempdir, 'memSerial.dat') );
        delete( fullfile(tempdir, 'memBuffer.dat') );
        
        % Create shared memory for a new process of MATLAB (serial communication)
        if ~isobject(smDevices)
            ovenInitial = zeros(64, 1);
            ovenInitial(21) = tempIni - offsetTemp(tempIni, offsetLow, tempLow, offsetHigh, tempHigh);
            ovenInitial(22) = sVoltage;
            ovenInitial(23) = sOutput;
            ovenInitial(24) = sProp;
            ovenInitial(25) = sInteg;            
            ovenInitial(26) = sCoolheat;
            ovenInitial(27) = sDeriv;
            ovenInitial(4) = 0; % self-destruct sequence
            
            smDevices = createSharedMemory(smDevices, 'memSerial.dat', ovenInitial);
        end
        
        % Check how many processes of MATLAB running
        [~,result] = system('tasklist /FI "imagename eq matlab.exe" /fo table /nh');
        
        % If there is only one process, then create two more
        if numel(strfind(result, 'MATLAB.exe')) == 1

            % Call another instance of MATLAB for serial communication
            system(['matlab -nosplash -nodesktop -minimize -r processDevicesBehavior(''', modeHeater, ''') &']);

        else
            figureTermination;
            error('Close other MATLAB processes first');
        end

        % Create a shared memory for disk writing
        sD.dimX = dimX;
        sD.dimY = dimY;
        sD.depthBit = depthBit;
        sD = prepareSharedMemory(sD);
        smDisk = createSharedMemory(smDisk, 'memBuffer.dat', sD.iniMat, sD.format, sD.formatFile);
        resetSharedMemory;
        
        % Call another instance of MATLAB for disk writing with some input arguments
        system(['matlab -nosplash -nodesktop -r processWriteToDisk(',...
            num2str(depthBit), ','...
            num2str(dimX), ',',...
            num2str(dimY),...
            ') &']);

    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function resetSharedMemory
        smDisk.Data.readyMaster = 0;
        smDisk.Data.readySlave = 0;
        smDisk.Data.destroySlave = 0;
        smDisk.Data.frame = 1;
        smDisk.Data.image(:, :) = 0;
        cBuffer = 1;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function resetInitialVariableValues
        frame = 1;
        frameZ = 1;
        tPrev = nan;
        skipInitialHold = 1;
        maxInt = [];
        if depthBit == 8
            vectorImage = zeros(dimY * dimX, numZStack, 'int8');
        else
            vectorImage = zeros(dimY * dimX, numZStack, 'int16');
        end
        tempOven = nan(numFrames, 2);
        tempDaq = nan(numFrames, 2);
        tempObj = nan(numFrames, 2);
        tempSet = nan(numFrames, 2);
        infoND = nan(numFrames, 5);
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function setInitialValuesForTemperatureControl

            % Set the voltage back to default
            sendOven(sVoltage, 'voltage');
            
            % Setting initial values for temperature ramp
            sendTemperature('initial');
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Keyboard Shortcuts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function keyPressed(~, event)
        switch event.Key

            case 'p'
                togglePreview;
            case 'b'
                set(handles.popupModeAcquisition, 'Value', 1);
                updateVariablesForSelectedAcquisitionMode(handles.popupModeAcquisition);
            case 'a'
                toggleAcquisition;
        
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% GUI Components
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Nested Functions for creating GUI components
    function createGUI
        % Get a path of this m-file
        [pathM, ~, ~] = fileparts(mfilename('fullpath'));
        
        handles = loadGUI([pathM, '\behaviorICE.fig']);
        
%         switch hostname
%             case 'GTX670'
%                 pos = get(handles.fig, 'Position');
%                 set(handles.fig, 'Position', [50 200 pos(3) pos(4)]);
%             otherwise
%                 %                 set(sH.fig, 'Position', [0.04 0.01 1 1]);
%         end

%         % For a compatibility reason
%         handles.axisImages(1) = handles.axisImagesR;
%         handles.axisImages(2) = handles.axisImagesG;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function associateCallbacks

        % Get JavaFrame for the figure for solving focusing issues
        warning off MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame
        handles.jFig = get(handles.fig, 'JavaFrame');
        
        % Assoicate handles to callback functions
        set(handles.fig, 'CloseRequestFcn', @figureTermination, 'KeyPressFcn', @keyPressed);
        set(handles.editPathFolder, 'Callback', @setPathFolder);
        set(handles.editTitle, 'Callback', @setTitle);        
        set(handles.editExposureR, 'Callback', @setExposures);        
        set(handles.editExposureG, 'Callback', @setExposures);        
        set(handles.popupModeAcquisition, 'Callback', @updateVariablesForSelectedAcquisitionMode);
        set(handles.editWaitFrame, 'Callback', @setWaits);
        set(handles.popupModeHeater, 'Callback', @updateVariablesForSelectedHeaterMode);
        set(handles.pushPreview, 'Callback', @togglePreview);
        set(handles.pushAcquire, 'Callback', @toggleAcquisition);
        set(handles.editDurationRamp, 'Callback', @setDuration);
        set(handles.editTemperatureInitial, 'Callback', @setRampVariables);
        set(handles.editTemperatureFinal, 'Callback', @setRampVariables);
        
        set(handles.pushStartRamp, 'Callback', @toggleTemperature);
        set(handles.checkSaveRamp, 'Callback', @toggleSave);
        set(handles.checkEnableOut, 'Callback', @sendOutput);
        set(handles.pushSendTuningValues, 'Callback', @sendTuningValues);
        set(handles.pushSendObjectiveOffsets, 'Callback', @sendObjectiveOffsets);
        
        set(handles.popupNameSample, 'Callback', @updateVariablesFromDynamicUIComponents);
        set(handles.popupObjective, 'Callback', @updateVariablesFromDynamicUIComponents);
        set(handles.popupTC, 'Callback', @updateVariablesFromDynamicUIComponents);       
        set(handles.checkRequestAnalysis, 'Callback', @setFlgRequestAnalysis);

        set(handles.editWaitInitialLaser, 'Callback', @setPulseVariables);
        set(handles.editWaitFinalLaser, 'Callback', @setPulseVariables);
        set(handles.editIntervalLaser, 'Callback', @setPulseVariables);
        set(handles.editDurationLaser, 'Callback', @setPulseVariables);
        set(handles.editRepeatLaser, 'Callback', @setPulseVariables);
        set(handles.editModulesLaser, 'Callback', @setPulseVariables);
        
        set(handles.editWaitInitialRamp, 'Callback', @setRampVariables);
        set(handles.editDurationRamp, 'Callback', @setRampVariables);
        
        set(handles.pushAlignCameras, 'Callback', @toggleAlign);

%         set(handles.nnn, 'Callback', @nnn);
%         set(handles.nnn, 'Callback', @nnn);
        

    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function updateStaticUIComponents
   
        % Set values and strings of the UI components
        set(handles.fig, 'Name', ['behaviorICE ', Ver]);
        set(handles.fig, 'MenuBar', 'none');
        set(handles.fig, 'ToolBar', 'none');
        set(handles.editPathFolder, 'String', pathFolder);
        set(handles.editTitle, 'String', titleExperiment);
        set(handles.editExposureR, 'String', exposure(1));
        set(handles.editExposureG, 'String', exposure(2));
        set(handles.editWaitFrame, 'String', waitFrame);
        set(handles.editTemperatureInitial, 'String', tempIni);
        set(handles.editTemperatureFinal, 'String', tempFin);
        set(handles.editSlopeTemperature, 'String', tempSlope);
        set(handles.editWaitInitialRamp, 'String', holdIni);
        set(handles.editDurationRamp, 'String', duration);
        set(handles.checkSaveRamp, 'Value', enableSave);
        set(handles.editProportional, 'String', sProp);
        set(handles.editIntegral, 'String', sInteg);
        set(handles.editDerivative, 'String', sDeriv);
        set(handles.editVoltage, 'String', sVoltage);
        set(handles.popupCoolHeat, 'Value', sCoolheat);
        set(handles.checkEnableOut, 'Value', sOutput);
        set(handles.editOffsetLow, 'String', offsetLow);
        set(handles.editOffsetHigh, 'String', offsetHigh);
        set(handles.editTemperatureOffsetLow, 'String', tempLow);
        set(handles.editTemperatureOffsetHigh, 'String', tempHigh);
        
        set(handles.editOffsetLowLow, 'String', offsetLowLow);
        set(handles.editOffsetHighLow, 'String', offsetHighLow);
        set(handles.editTempLowLow, 'String', tempLowLow);
        set(handles.editTempHighLow, 'String', tempHighLow);
        
        set(handles.editOffsetLowHigh, 'String', offsetLowHigh);
        set(handles.editOffsetHighHigh, 'String', offsetHighHigh);
        set(handles.editTempLowHigh, 'String', tempLowHigh);
        set(handles.editTempHighHigh, 'String', tempHighHigh);
        set(handles.editWaitInitialLaser, 'String', waitInitialPulse);
        set(handles.editWaitFinalLaser, 'String', waitFinalPulse);
        set(handles.editIntervalLaser, 'String', intervalPulse);
        set(handles.editDurationLaser, 'String', durationPulse);
        set(handles.editPlanLaser, 'String', mat2str(planPulse),...
                                   'TooltipString', mat2str(planPulse));
        set(handles.editRepeatLaser, 'String', repeatPulse);
        set(handles.editModulesLaser, 'String', modulesPulse);        
        set(handles.checkRequestAnalysis, 'Value', flgRequestAnalysis);
        
%         set(handles.nnn, 'nnn', nnn);
        
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function loadDynamicUIComponents
        S = load([pathM, '\dc.mat']); % Reads dc.mat for stored lists and last used values
        dc = S.dc;
        set(handles.popupNameSample,        'String', dc.popupNameSample.list,...
                                            'Value', dc.popupNameSample.last);
        set(handles.popupObjective,         'String', dc.popupObjective.list,...
                                            'Value', dc.popupObjective.last);
        set(handles.popupTC,                'String', dc.popupTC.list,...
                                            'Value', dc.popupTC.last);
        set(handles.popupModeAcquisition,   'String', dc.popupModeAcquisition.list,...
                                            'Value', dc.popupModeAcquisition.last);
        set(handles.popupModeHeater,        'String', dc.popupModeHeater.list,...
                                            'Value', dc.popupModeHeater.last);
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function updateVariablesFromDynamicUIComponents(varargin)
        if nargin > 0 % means a callback, so save the specified variable then reload dc.mat
            saveDynamicUIComponent(varargin{1});
            loadDynamicUIComponents;
        end
        % Update all relevent variables from structure dc
        nameSample = dc.popupNameSample.list{dc.popupNameSample.last};
        lensObjective = dc.popupObjective.list{dc.popupObjective.last};
        tempCultivation = dc.popupTC.list{dc.popupTC.last};
        modeAcquisition = dc.popupModeAcquisition.list{dc.popupModeAcquisition.last};
        modeHeating = dc.popupModeHeater.list{dc.popupModeHeater.last};
        
        makeExperimentTitle;
        updateStaticUIComponents;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function updateVariablesForSelectedAcquisitionMode(varargin)
        if nargin % Indicates that the function is called as a callback from a UI component
            saveDynamicUIComponent(varargin{1});
            loadDynamicUIComponents;
            val = get(varargin{1}, 'Value');
        else % Reload and reset the UI components
            loadDynamicUIComponents;
            val = dc.popupModeAcquisition.last;
        end
        modeAcquisition = dc.popupModeAcquisition.list{val};
        
        updateVariablesForSelectedModes;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function updateVariablesForSelectedHeaterMode(varargin)
        if nargin % Indicates that the function is called as a callback from a UI component
            saveDynamicUIComponent(varargin{1});
            loadDynamicUIComponents;
            val = get(varargin{1}, 'Value');
        else % Reload and reset the UI components
            loadDynamicUIComponents;
            val = dc.popupModeHeater.last;
        end
        modeHeating = dc.popupModeHeater.list{val};
        
        updateVariablesForSelectedModes;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function updateVariablesForSelectedModes

        switch modeHeating
            case 'pulse'
                % ramp variables
                tempIni = 23;
                tempFin = 33;
%                 durationPulse = 30;
%                 waitInitialPulse = 16;
%                 waitFinalPulse = 9;
%                 intervalPulse = 25;

                durationPulse = 20;
                waitInitialPulse = 50;
                waitFinalPulse = 0;
                intervalPulse = 30;                
                
                repeatPulse = 5;
                modulesPulse = 1;
                
                makePlanPulse;
                
                mmc.setProperty('Shutter-A', 'State', false); % IR shutter closed

            otherwise % For all non-zap
                % ramp variables
                tempIni = 23;
                tempFin = 33;
                tempSlope = 0.05; % PFS starts to fail at faster rate above ~30C
                holdIni = 100;
                duration = 500;
                
                % pulse variables
                planPulse = nan;
                durationPulse = nan;
                waitInitialPulse = nan;
                waitFinalPulse = nan;
                intervalPulse = nan;
                repeatPulse = nan;
                modulesPulse = nan;
        end
        
        switch modeAcquisition % For variables regardless of zap or non-zap
            case 'burst'
                waitFrame = 0;
                exposure(1) = 33;
                exposure(2) = 33;
%                 flgIR = false;
                flgFastAcquisition = false;
                flgRequestAnalysis = false;
            case 'discrete'
                waitFrame = 0;
                exposure(1) = 20;
                exposure(2) = 20;
%                 flgIR = false;
                flgFastAcquisition = false;
                flgRequestAnalysis = false;
        end
        
        switch modeAcquisition
            case {'ND', 'BCECF-ND'}
                dimZ = 40;
                stepZ = 2;
            otherwise
                dimZ = 1;
                stepZ = 1;
        end
        numZStack = ceil(dimZ / stepZ);

        dimXRaw = 2160;
        dimYRaw = 2560;
        dimX = 2048;
        dimY = 2048;
        posY1 = 245;
        posY2 = dimYRaw - dimY - posY1 + 1;
        posX1 = 92;
        posX2 = dimXRaw - dimX - posX1 + 1;
        posYDisp1 = 310;
        posYDisp2 = dimXRaw - 1600 - posYDisp1 + 1;

        makeExperimentTitle;
        updateStaticUIComponents;
        setTrackingPlanes;
        handles.jFig.getAxisComponent.requestFocus;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function saveDynamicUIComponent(varargin)
        val = get(varargin{1}, 'Value');
        dc.( get(varargin{1}, 'Tag') ).last = val;
        save([pathM, '\dc.mat'], 'dc'); % Save selected value of a popup menu to dc.mat file
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function setTrackingPlanes
       set(handles.popupTrackingPlane,...
           'String', cellstr(num2str((baseZ:stepZ:dimZ-stepZ)')), 'Value', 1);
       % dimZ is actually z-dimension - z-step for back-compatibility
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function makeExperimentTitle
        switch modeHeating
            case 'ramp'
                titleExperiment = [nameSample, '_@', tempCultivation, 'C_', modeHeating, '-',...
                    num2str(tempIni), '-', num2str(tempFin), '_', num2str(duration), 's',...
                    lensObjective];
            case 'pulse'
                titleExperiment = [nameSample, '_@', tempCultivation, 'C_', modeHeating, '-',...
                    num2str(tempIni), '-', num2str(tempFin), '_', num2str(duration), 's',...
                    lensObjective];
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Other Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [lg, strOut] = formatHeaderChar(cellStr)

sz = size(cellStr, 1);
strOut = [];

for z = 1:sz
    title = ['<', cellStr(z, 1), '>'];
    data = cellStr(z, 2);
    strOut = [strOut, title, data]; 
end

strOut = [strOut{:}];
lg = length(strOut);

end


