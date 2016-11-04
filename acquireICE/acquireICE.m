function acquireICE(modeApp)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                         acquireICE.m                               
                                          Ver = '0.07';
%                                 Oct. 04, 2012 by Ippei Kotera                      
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Version History
%
% Ver. 0.01: Oct. 04, 2012; First Release (as ctrlTEC).
%
% Ver. 0.02: Oct. 16, 2012; Added image acquisition capabilities through MMCore. Renamed to
% neuroHeater.
%
% Ver. 0.03: Nov. 22, 2012; Implemented parallel acquisition of serial and imaging data in two
% separate instances for faster FPS. Also implemented was the circular buffer for image acquisition
% insead of serial snap acquisions.
%
% Ver. 0.04: Nov. 27, 2012; Separated file saving to disk functions in another instance to boost FPS
% while saving.
%
% Ver. 0.05: May. 30, 2013; Abandoned multi-instance structure to avoid strange pixel intensity
% fluctuations. Implemented objective scanner, IR laser, and LED contols with NI Daq. Implemented 5D
% acquisition. Added laser-heating capability. Lots of bug fixes. 
%
% Ver. 0.06: Jun. 12, 2013; Added BCECF support, re-designed saving mode variables in accordance
% with analyzeICE v0.06.
%
% Ver. 0.07: Aug. 22, 2014; (Renamed to acquireICE from neuroHeater) Overhauled most part of the
% software. New GUI with .fig format for easier future modifications. Re-introduced separate
% process for Oven control; image fluctuation problem finally solved. Main loop now exits to timer
% subroutine so that user can get command control while the script is in idle instead of infinite
% while-loop. Integrated automatic analysis initiation by other CUDA-capable stations. Each
% experimental conditions are dynamically organized so that different experiments can be performed
% by choosing appropriate mode from a pull-down menu. Performance-tunings for ND acquistions have
% been extensively carried out; slow processes are placed between image-stacks to reach ~13 fps. 

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
modeHeater = 'zap';
% modeHeater = 'TEC';

flgTimer = true;
flgRepeat = false;
flgProfile = false;
% flgVerticalDisplay = true;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Static variables

% % By 0.003 TC when Coolant temp is 14oC with 60xNA1.2 WI obj
% offsetLowLow    =    -3; tempLowLow      =  22.0;
% offsetHighLow   =   7.0; tempHighLow     =  24.0;
% offsetLowHigh   = -21.4; tempLowHigh     =  22.0;
% offsetHighHigh  = -13.5; tempHighHigh    =  24.0;

% By 0.003 TC when Coolant temp is 14oC with 20x NA0.45 Dry Obj
offsetLowLow    = -0.2; tempLowLow      =  22.0;
offsetHighLow   =  0.7; tempHighLow     =  24.0;
offsetLowHigh   = -7.0; tempLowHigh     =  22.0;
offsetHighHigh  = -6.0; tempHighHigh    =  24.0;

pathFolder = 'H:\Data\working\';

flgPFS = false;

intensityBlueLED = 1.2;

waitStage = 5; % Down to 5ms.
waitPrePFS = 10; % As low as 0ms if LED is used.
waitPFS = 100; % 150ms when LED is used. User larger value if PFS starts to fail.
waitAfterLedForBCECF = 100; % Less than 100ms (exposure x 2 + this value) will result in fluctuation
% waitAfterDaq = 0; % minimum ~50 ms to avoid intensity fluctuation after Daq communication, 
                  % Could be 0 when LED is used
% waitSnap = 3; % Wait after snapImage on MM. 3 ms seems to be sufficient to supress fluctuation
waitSnap = 10;

waitTracking = 100;
gainEM(1) = 5;
gainEM(2) = 40;
exposureIR = 50;
intensityRedLED = 5;

sizePixel = 16000; % Pixel size of CCD in nm
magnification = 60; % Total magnification of the microscope

sProp = 10;
sInteg = 1;
sVoltage = 10;
sCoolheat = 2;
sOutput = 1;

% Daq thermocouple calibration to a standard thermometer
offsetDaq = 0.7;  % 140321 T-type

vLaserAtTLaser1 = 0;
vLaserAtTLaser2 = 180;
tLaser1 = 18;
tLaser2 = 28;

frameZ = 1;
baseZ = 0;
dimZ = nan;
stepZ = nan;

modeExcitation = 'LED';
modeLoop = 'startWalk';
modeCamera = 'standby';

% Figure font
fs = 9;
fn = 'Meiryo UI';

switch modeApp
    case {'imaging', 'imagingNoTemp'}
        mmc = evalin('base', 'mmc');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Dynamic variables 

% For images
hImg(1) = nan; hImg(2) = nan; hImgAlignment(1:2) = nan;  nameFileICE = {'1.tiff'; '2.tiff'};

% For tracking
flgTracking = false; posX = nan; posY = nan; hPoint = nan;

% For BCECF
planBCECF = nan; intensityLedBCECFL = nan; intensityLedBCECFH = nan; flgIntervalBCECF = false;
flgBurstBCECF = false; waitInitialBCECF = nan; waitFinalBCECF = nan; intervalBCECF = nan;
stateAcquireBCECF = false; stateFirstHalfBCECF = false;

% For experiment title
titleExperiment = []; nameSample = []; tempCultivation = []; lensObjective = [];

% For temperature controls
tempIni = nan; tempFin = nan; tempSlope = nan; holdIni = nan; duration = nan;
zapPower = nan; planLaser = nan; zapDuration = nan;
smZap = []; smOven = []; enableSave = false;
rTemperature = nan; rOutput = nan; rVoltage = nan;
waitInitialLaser = nan; waitFinalLaser = nan; intervalLaser = nan; repeatLaser = nan; modulesLaser = nan;
durationLaser = nan; planLaser = nan; planIndexLaser = nan; 
offsetLow = nan; tempLow = 23; offsetHigh = nan; tempHigh = 33; stateRapidCooling = false; 
stateCountdown = false;

% For cube and IR controls
slotOriginal = nan; slotCurrent = nan; stateCube = []; stateIR = false; stateFinishedIR = false;
flgIR = false;

% For microscope controls
waitFrame = nan; exposure(1) = nan; exposure(2) = nan; dataTC = nan; dataV = nan; dataOB = nan;
frame = 1; bframe = 0; framePrevPlot = 1; tFPS = 0; FPS = 0; selectedZ = nan; frameTracking = 1;
flgEndZ = true; flgShutterState = false; flgCameraAlignment = false; posZPrevious = nan;
flgDisplayAllFrames = true; flgFastAcquisition = false;
flgRequestAnalysis = false; numZStack = nan;

% For device objects
objDaqAOPiezo = nan; objDaqAOLEDBlue = nan; objDaqAOLEDRed = nan; objThor = nan;

% Miscellaneous
pathM = []; dc = []; nameFolder = []; tmr = [];

% Fig handles and positions
handles = []; pos = []; posFig = nan;

% Variables for main loop
tPrev = nan;
% tc1 = nan;
tStart = nan;
tCool = nan;
skipInitialHold = nan;
stateLastSetOfBCECF = [];
stateZap = false;
stateBCECF = [];
planIndexBCECF = nan;
fidImg = nan;
normalTermination = false;
err = [];
initialImageReady = false;
flgTerminate = false;
status = [];
% nc = 0;
objAI = [];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Initialization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
initDaqAI;
hListnDaqTC = objDaqAI.addlistener('DataAvailable', @pushDataAI);
objDaqAI.startBackground;

% Create GUI components
createGUI;
associateCallbacks;
loadDynamicUIComponents;
updateVariablesFromDynamicUIComponents; % load dynamic UI components first
updateVariablesForSelectedModes;
setTrackingPlanes;

updateOffsets;
initiateMatlabProcesses;
initDaqAOPiezo;
initDaqAOLED;
initThor;

switch modeApp
    case {'imaging', 'noimaging'}
end

% Some dynamic variables after GUI is created
vectorImage = [];
vectorImageTracking = zeros(dimY(1) * dimX(1), 2, 'uint16');
% vectorStack = [];
img(:, :, 1) = nan(dimY(1), dimX(1));
img(:, :, 2) = nan(dimY(2), dimX(2));
imgR = zeros(dimY(1), dimX(1), 3, 'uint16');
imgG = zeros(dimY(1), dimX(1), 3, 'uint16');
imgTrackingCurrent = nan(dimY(1), dimX(1));
imgTrackingTemplateFFT = nan(dimY(1), dimX(1));
numFrames = duration * 30;
tempRepeat = tempIni - 0.05;
tempOven = nan(numFrames, 2);
tempDaq = nan(numFrames, 2);
tempObj = nan(numFrames, 2);
tempSet = nan(numFrames, 2);
infoND = nan(numFrames, 5);
infoIR = nan(numFrames, 5);
vLaser = nan(numFrames, 1);

tOven = tic;
while true
    if smOven.Data(2) == 1
        sendOven(sVoltage, 'voltage');
        break
    else
        prt('Waiting for processOven...');
        pause(1);
    end
    if toc(tOven) > 10
        prt('Oven not ready');
        return
    end
end


% Retrieve Oven values from the shared memory
readOven;

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
                    tStart = tic;

                    setDuration;
                    getRampValues(); % Get ramp values from uicontrols
                    sendTuningValues();
                    deletePlots;
                    createPlots;
                    resetInitialVariableValues;
                    setInitialValuesForTemperatureControl;
                    moveStage;

                    switch modeHeater
                        case {'laser', 'zap'}
                            sendLaser('initialize');
                    end
                    
                    modeLoop = 'run';
                    
                case 'run' % 'run' is acquisition + temperature control, or just temperature control
                    %%
%---------------------------------------------------------------------------------------------------
                    % Temperature control (skip if pre-acquisition)
                    switch modeCamera
                        case {'acquisition', 'postAcquisition', 'standby'}
                            controlRamp; % temperture calculation only

                            switch modeCamera
                                case {'acquisition', 'postAcquisition'}
                                    % if ~( strcmp(modeCamera, 'postAcquisition') && strcmp(modeAcquisition, 'burst') ) % exclude
                                    updateImages;
                                    % end
                            end

                            getTimesAndTemperatures; % Readings from NI devices (<0.05ms)
                            if ~flgFastAcquisition || ( flgFastAcquisition && flgEndZ )
                                updatePlots;
                                readOven; % from shared memory < 1 ms
                                updateIndicators;
                                updateOffsets;
                                changeTemperature;
                            end
                    end
%---------------------------------------------------------------------------------------------------
                    % Image contol
                    switch modeCamera
                        % No camera is used
                        case 'standby'
                            frame = frame + 1;
                            sleep(30);
                        case 'preAcquisition'
                            performPFS;
                            prepareImages;
                        case 'acquisition'
                            frame = frame + 1;
                        case 'postAcquisition'
                            frame = frame + 1;
                            % Stop circular buffer if in burst mode
                            switch modeAcquisition
                                case {'burst', 'discrete'}
                                    stopBurst;
                                    saveVariables;
                                    modeCamera = 'finalization';
                                case 'BCECF-burst'
                                    stopBurst;
                                    modeAcquisition = 'BCECF';
                                    stateCube = 'L';
                                    stateLastSetOfBCECF = true;
                                    updateImages; % Acquire L/H images one last time
                                    readOven;
                                    getTimesAndTemperatures;
                                    updatePlots;
                                    updateIndicators;
                                    updateOffsets;
                                    changeTemperature;
                                    frame = frame + 1;
                            end
                            
                            % This is the end of image acquisition: For non-ND, flgEndZ is always
                            % true. For ND acquisition it has to be at the end of the stack. For
                            % BCECF, it has to be the last cube.
                            if (strcmp(modeAcquisition, 'ND') && flgEndZ) ||... % for ND
                               (strcmp(modeAcquisition, 'BCECF') && strcmp(stateCube, 'L')) ||... % for BCECF
                               (strcmp(modeAcquisition, 'BCECF-ND') && strcmp(stateCube, 'L') && flgEndZ) % for BCECF-ND
                                
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
                            initiateRapidCooling;
                            stateFinishedIR = false;
                            frame = 1;
                            
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
                    
                    % Wait between frames. Ignore only if it's in BCECF mode && BCECF/H cube is
                    % coming next
                    if strcmp(modeAcquisition, 'BCECF') && strcmp(stateCube, 'H')
                        % Ignoring the wait
                    elseif waitFrame
                        sleep(waitFrame);
                    end

                    if  (strcmp(modeAcquisition, 'ND') || strcmp(modeAcquisition, 'BCECF-ND') )&&...
                           ( strcmp(modeCamera, 'acquisition') ||...
                             strcmp(modeCamera, 'postAcquisition') )
                         
                        countUpFrameZ; % This has to be after the last frameZ/flgEndZ use
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
                    moveStage;
                    
                    if ~stateRapidCooling
                        sendTemperature('initial');
                    end
                    
                    switch modeAcquisition
                        case 'BCECF'
                            stateBCECF = true;
                            planIndexBCECF = 1;
                            stateCube = 'L';
                    end
%                     sleep(200);

                case 'walk' % 'walk' is either preview or possibility to exit to 'loopIdle'
                    %%
                    switch modeCamera
                        case 'prePreview'
                            performPFS;
                            prepareImages;
                            sleep(30);
                        case 'preview'
                            updateImages;
                            frame = frame + 1;
                            
                        case 'postPreview' % Post-acquisition sequence
                            updateImages;
                            frame = frame + 1;
                            % Stop circular buffer if in burst or BCECF-burst mode
                            switch modeAcquisition
                                case 'burst'
                                    stopBurst;
                                    modeCamera = 'standby';
                                case 'BCECF-burst'
                                    stopBurst;
                                    modeAcquisition = 'BCECF';
                                    stateCube = 'L';
                                    stateLastSetOfBCECF = true;
                                    updateImages;
                            end
                            
                            % Stop preview if z-stack reaches the last plane or...
                            % BCECF reaches last cube or...
                            % BCECF-ND reaches last plane and cube
                            if (~strcmp(modeAcquisition, 'BCECF') && flgEndZ) ||... % for non-BCECF
                                (strcmp(modeAcquisition, 'BCECF') && strcmp(stateCube, 'L')) ||... % for BCECF
                                (strcmp(modeAcquisition, 'BCECF-ND') && strcmp(stateCube, 'L') && flgEndZ) % for BCECF-ND
                            
                                modeCamera = 'standby';
                                
                                % End session for camera alignment
                                if flgCameraAlignment
                                    flgCameraAlignment = false;
                                    delete(handles.figAlignCameras);
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
                    
                    if ~flgFastAcquisition || ( flgFastAcquisition && flgEndZ )
                        readOven;
                        updateIndicators;
                        updateOffsets;
                        drawnow;
                    end
                    
                    if flgRepeat && dataTC < tempRepeat
                        modeAcquisition = 'BCECF';
                        % endRapidCooling;
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
            
            readOven;
            
            changeTemperature;
            
            updateIndicators;
            
            updateOffsets;
            pause(0.01);
            
        end
        
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function prepareImages
        
        % Set correct trigger modes
        mmc.setProperty('Andor1', 'Trigger', 'Software');
        mmc.setProperty('Andor2', 'Trigger', 'Software');
        
        % Get the current cube slot
        slotCurrent = str2double(mmc.getProperty('TIFilterBlock1', 'State'));
        
        % Somehow, exposure needs to be re-set at this point for consistent exposure setting
        setExposures;
        setEmGain;
        acquireInitialImages;
  
        if strcmp(modeCamera, 'preAcquisition')
            prepareImageFiles;
        end
        
        tFPS = tic;
        initialImageReady = true;
        
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function updateImages

        stateAcquireBCECF = false;
        
        if strcmp(modeCamera, 'acquisition') || strcmp(modeCamera, 'postAcquisition')
            stateAcquisition = true;
        else
            stateAcquisition = false;
        end

        if flgIR, changeCubeForIR; end

        switch modeAcquisition
            case 'burst'
                recordInfo;
                retrieveAndDisplayImages;
                if stateAcquisition, saveImages(vectorImage(:, frameZ, :)); end
            case 'discrete'
                recordInfo;
                snapImage;
                retrieveAndDisplayImages;
                if stateAcquisition, saveImages(vectorImage(:, frameZ, :)); end
            case 'ND'
                snapImage; % exposure + 20ms
                recordInfo; % <1ms
                moveStage; % ~10ms
                retrieveAndDisplayImages; % ~25ms
                if stateAcquisition
                    saveImagesND;
                end
            case 'BCECF-ND'
                if frameZ == 1
                    changeCubeForBCECF;
                end
                snapImage; % exposure + 20ms
                recordInfo; % <1ms
                moveStage; % ~10ms
                retrieveAndDisplayImages; % ~25ms
                if stateAcquisition
                    saveImagesND;
                end                
            case 'BCECF'
                if flgIntervalBCECF
                    executePlanBCECF; % Raise acquisition flag according to planBCECF
                else 
                    stateAcquireBCECF = true; % for non-interval BCECF, flag every time
                end
                
%                 if stateFirstHalfBCECF
%                     frame = 1;
%                 end
                if (frame == 1 || flgIntervalBCECF || stateLastSetOfBCECF) && stateAcquireBCECF
                    changeCubeForBCECF;
                    snapImage;
                    bframe = bframe + 1;
                    recordInfo;
                    retrieveAndDisplayImages;
                    
                    changeCubeForBCECF;
                    snapImage;
%                     bframe = bframe + 1;
                    recordInfo;
                    retrieveAndDisplayImages;                    
                    
                    if stateAcquisition, saveImages(vectorImage(:, frameZ, :)); end
%                     if stateFirstHalfBCECF
% %                        frame = 2;
%                        stateFirstHalfBCECF = false;
%                     else
%                        stateFirstHalfBCECF = true;
%                     end                    
                elseif frame == 2 && flgBurstBCECF
                    changeToBurstMode;
                    recordInfo;
                    retrieveAndDisplayImages;
                    if stateAcquisition, saveImages(vectorImage(:, frameZ, :)); end
                end
            case 'BCECF-burst'
                recordInfo;
                retrieveAndDisplayImages;
                if stateAcquisition, saveImages(vectorImage(:, frameZ, :)); end
        end    
        
        if flgEndZ
            FPS = 1/(toc(tFPS) / numZStack);
        end

%         % Use PFS to focus if the last plane has just acquired
%         if flgPFS && ~flgBurstBCECF && (...
%            strcmp(modeAcquisition, 'ND') && flgEndZ ||...
%            strcmp(modeAcquisition, 'BCECF-ND') && flgEndZ && strcmp(stateCube, 'L')||...
%            strcmp(modeAcquisition, 'BCECF') && strcmp(stateCube, 'L') ||...
%            strcmp(modeAcquisition, 'discrete') )
        performPFS;
%         end
        % Tracking by image registration
        if (strcmp(modeAcquisition, 'ND') || strcmp(modeAcquisition, 'discrete'))...
                && flgEndZ && flgTracking && ~stateIR && ~flgBurstBCECF
            trackByRegistration;
        end
        if flgEndZ
            tFPS = tic;
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function executePlanBCECF
        
        if length(planBCECF) >= planIndexBCECF
            switch stateCube
                case 'L'
                    if length(planBCECF) >= planIndexBCECF && toc(tStart) > planBCECF(planIndexBCECF)
                        stateAcquireBCECF = true;
                        planIndexBCECF = planIndexBCECF + 1;
                        
                    else
                        pause(0.1);
                    end
                case 'H'
%                     stateAcquireBCECF = true;
%                     if length(planBCECF) < planIndexBCECF
%                         stateBCECF = false;
%                     end
                    
            end
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function retrieveAndDisplayImages
        
        switch modeAcquisition
            case {'BCECF', 'BCECF-ND'}
                switch stateCube
                    case 'L' % This is actually BCE/H cube
                        vectorImage(:, frameZ, 2) = mmc.getImage(0); % green channel
                        mmc.getImage(1); % dump the buffer on red channel
                    case 'H' % This is actually BCE/L cube
                        vectorImage(:, frameZ, 1) = mmc.getImage(0); % green channel
                        mmc.getImage(1); % dump the buffer on red channel
                end
            case 'BCECF-burst'
                vectorImage(:, frameZ, 2) = mmc.getImage(0);
            otherwise
                vectorImage(:, frameZ, 1) = mmc.getImage(0);
                vectorImage(:, frameZ, 2) = mmc.getImage(1);
        end

        % Copy the current image for tracking
%         if frameZ == frameTracking
%             vectorImageTracking = vectorImage(:, frameZ, :);
%         end
        
        if flgDisplayAllFrames
            switch modeAcquisition
                case {'BCECF', 'BCECF-ND'}
                    switch stateCube
                        case 'L'
                            img(:, :, 2) = rot90( reshape( vectorImage(:, frameZ, 2), [dimY(1), dimX(1), 1] ) );
                            overwriteCData;
                        case 'H'
                            img(:, :, 1) = rot90( reshape( vectorImage(:, frameZ, 1), [dimY(1), dimX(1), 1] ) );
                            overwriteCData;
                    end
                otherwise
                    img(:, :, 1) = rot90( reshape( vectorImage(:, frameZ, 1), [dimY(1), dimX(1), 1] ) );
                    img(:, :, 2) = rot90( reshape( vectorImage(:, frameZ, 2), [dimY(1), dimX(1), 1] ) );
                    overwriteCData;
                    imgTrackingCurrent = img(:, :, 1);
            end
        elseif flgEndZ
            img(:, :, 1) = rot90( reshape( vectorImage(:, frameTracking, 1), [dimY(1), dimX(1), 1] ) );
            img(:, :, 2) = rot90( reshape( vectorImage(:, frameTracking, 2), [dimY(1), dimX(1), 1] ) );
            overwriteCData;
            imgTrackingCurrent = img(:, :, 1);
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function overwriteCData
        if flgCameraAlignment
            imgOL(:, :, 1) = uint16( img(:, :, 1) );
            imgOL(:, :, 2) = uint16( img(:, :, 2) );
            imgOL(:, :, 3) = 0;
            sl = stretchlim(imgOL, [.001 .999]);
            imgOL = imadjust(imgOL, sl);
            
            % Crosshair in the middle
            imgOL(246:266, 256, 3) = 2^16;
            imgOL(256, 246:266, 3) = 2^16;
            set(hImgAlignment, 'CData', imgOL);
        else
            
%             imgR(:, :, 1) = img(:, :, 1);
%             imgG(:, :, 2) = img(:, :, 2);
% %             slR = stretchlim(imgR, [.001 .999]);
% %             slG = stretchlim(imgG, [.001 .999]);
% %             imgR = imadjust(imgR, slR);
% %             imgG = imadjust(imgG, slG);
%             set( hImg(1), 'CData', imgR );
%             set( hImg(2), 'CData', imgG );
            
            
%             
            set( hImg(1), 'CData', img(:, :, 1) );
            set( hImg(2), 'CData', img(:, :, 2) );
%             prt(max(img(:)));
        end
        
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function countUpFrameZ
        
        if flgEndZ
            frameZ = 1;
            flgEndZ = false;
        else
            frameZ = frameZ + 1;
            if frameZ >= numZStack % if the last z-plane is reached
                flgEndZ = true;
            end
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function acquireInitialImages
        switch modeAcquisition
            case 'burst'
                % Start sequence acquisition
                mmc.setCircularBufferMemoryFootprint(100);
                mmc.initializeCircularBuffer();
                outputAnalogLED(objDaqAOLEDBlue, intensityBlueLED);
                mmc.startSequenceAcquisition('Andor1', 100000, 0, false);
                mmc.startSequenceAcquisition('Andor2', 100000, 0, false);
                flgEndZ = true;
            case 'discrete'
                % Snap one image and put it in the buffer
                snapImage;
                flgEndZ = true;
            case 'ND'
                mmc.enableContinuousFocus(0);
                snapImage;
                flgEndZ = false;
            case 'BCECF-ND'
                mmc.enableContinuousFocus(0);
                stateCube = 'H';
                changeCubeForBCECF;
                stateLastSetOfBCECF = false;
%                 intensityBlueLED = intensityLedBCECFH;
                snapImage;
                flgEndZ = false;
            case 'BCECF'
                % Change the filter cube slot #5 (BCECF/H)
                mmc.setProperty('TIFilterBlock1', 'State', 5);
                stateCube = 'H';
                changeCubeForBCECF;
                stateLastSetOfBCECF = false;
                flgEndZ = true;
%                 intensityBlueLED = intensityLedBCECFH;
                snapImage;
        end

        % Get images from the buffer
        
        for ind = 1:2
            vi(:, ind) = mmc.getImage(ind - 1);
            img(:, :, ind) = rot90(reshape(vi(:, ind), [dimY(1), dimX(1), 1]));
        end
        
        switch modeAcquisition
            case {'BCECF', 'BCECF-ND'}
                img(:, :, 2) = img(:, :, 1);
        end
        
        % For dual camera calibration
        if flgCameraAlignment

            % Make overlay in RGB
            imgOL(:, :, 1) = uint16(img(:, :, 1));
            imgOL(:, :, 2) = uint16(img(:, :, 2));
            imgOL(:, :, 3) = 0;
            imgOL = imadjust(imgOL, [0 0 0; .01 .5 1]);
            hImgAlignment = imagesc(imgOL, 'Parent', handles.axisAlignCameras);
            set(hImgAlignment, 'EraseMode', 'none');
            set(handles.axisAlignCameras, 'XTick', [], 'YTick', []);
            handles.jFig.getAxisComponent.requestFocus;
            % For regular display
        else
            for ind = 1:2
                hImg(ind) = imagesc(img(:, :, ind), 'Parent', handles.axisImages(ind));
                colormap(gray(256));
                
%                 sq = 0:1/255:1;
%                 zr = zeros(256, 1);


                set(hImg(ind), 'EraseMode', 'none');
                set(handles.axisImages(ind), 'Units', 'pixels');
                set(handles.axisImages(ind), 'XTick', [], 'YTick', []);
                set(handles.axisImages(ind), 'xlimmode','manual',...
                    'ylimmode','manual',...
                    'zlimmode','manual',...
                    'climmode','manual',...
                    'alimmode','manual');
%                 set(hImg(ind), 'EraseMode', 'none');
            end
            set(hImg(1), 'ButtonDownFcn', @clickImage);
        end
        
        drawnow;
        
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
            if flgIR
                numSaveImages = 4;
            else
                numSaveImages = 2;
            end
            
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
                hdrNum{ind}(1, 1) = dimX(ind); %#ok<*AGROW>
                hdrNum{ind}(1, 2) = dimY(ind);
                hdrNum{ind}(1, 3) = dimZ;
                hdrNum{ind}(1, 4) = baseZ;
                hdrNum{ind}(1, 5) = stepZ;
                hdrNum{ind}(1, 6) = waitStage; 
                hdrNum{ind}(1, 7) = waitPFS; 
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
                hdrChr{ind} = [hdrChr{ind}, repmat(char(0), 1, 2048 - length(hdrChr{ind}))]; 
                % Write header information to the ice files on disk
                fidImg(ind) = writeICE(nan, nan, nameFileICE{ind}, hdrNum{ind}', hdrChr{ind});
                
            end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function changeCubeForIR
        if frame == 1;
            if flgIR && ~stateFinishedIR
                switch modeAcquisition
                    case {'discrete', 'ND'}
                        % Save the current slot #
                        slotOriginal = str2double(mmc.getProperty('TIFilterBlock1', 'State'));
                        % Change the filter cube to slot #4 (mNept)
                        slotCurrent = 3; % The slot # starts from 0 in mmc
                        mmc.setProperty('TIFilterBlock1', 'State', slotCurrent);
                        mmc.setProperty('Andor1', 'Exposure', exposureIR);
                        mmc.setProperty('Andor2', 'Exposure', exposureIR);
                        sleep(500);
                        stateIR = 1;
                end
            end
        elseif (...
                (frame == 2 && strcmp(modeAcquisition, 'discrete')) ||...
                (frame == dimZ / stepZ + 1 && strcmp(modeAcquisition, 'ND'))...
                )
            
            if flgIR && ~stateFinishedIR
                switch modeAcquisition
                    case {'discrete', 'ND'}
                        % Change the filter cube back to original position
                        slotCurrent = slotOriginal;
                        mmc.setProperty('TIFilterBlock1', 'State', slotCurrent);
                        %                         mmc.setShutterOpen(0);
                        mmc.setProperty('Andor1', 'Exposure', exposure(1));
                        mmc.setProperty('Andor2', 'Exposure', exposure(2));
                        stateIR = 0;
                        frame = 1;
                        stateFinishedIR = 1;
                        sleep(500);
                        tStart = tic;
                end
            end
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
                if stateIR
                    infoIR(frame, 1) = frame;
                    infoIR(frame, 2) = frameZ;
                    infoIR(frame, 3) = dataV * 10;
                    infoIR(frame, 4) = toc(tStart);
                    infoIR(frame, 5) = slotCurrent;
                elseif flgIntervalBCECF
                    infoND(bframe, 1) = bframe;
                    infoND(bframe, 2) = frameZ;
                    infoND(bframe, 3) = dataV * 10;
                    infoND(bframe, 4) = toc(tStart);
                    infoND(bframe, 5) = slotCurrent;
                else
                    infoND(frame, 1) = frame;
                    infoND(frame, 2) = frameZ;
                    infoND(frame, 3) = dataV * 10;
                    infoND(frame, 4) = toc(tStart);
                    infoND(frame, 5) = slotCurrent;
                end
%             case 'BCECF'
%                 infoBCECF(frame, 1) = frame;
%                 infoBCECF(frame, 2) = slotCurrent;
%                 infoBCECF(frame, 3) = toc(tStart);
%                 prt(infoBCECF(frame, 1), infoBCECF(frame, 2), infoBCECF(frame, 3));
%             case 'BCECF-burst'
%                 infoBCECF(frame, 1) = frame;
%                 infoBCECF(frame, 2) = slotCurrent;
%                 infoBCECF(frame, 3) = toc(tStart);
%                 prt(infoBCECF(frame, 1), infoBCECF(frame, 2), infoBCECF(frame, 3));
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function changeCubeForBCECF
        switch stateCube
            case 'L'
                % Change the filter cube to slot #5 (BCECF/L)
                slotCurrent = 4; % Slot #5 (TIFilterBlock1 starts from 0)
                mmc.setProperty('TIFilterBlock1', 'State', slotCurrent);
                intensityBlueLED = intensityLedBCECFL;
                stateCube = 'H'; % for the next acquisition
            case 'H'
                % Change the filter cube to slot #6 (BCECF/H)
                slotCurrent = 5; % Slot #6
                mmc.setProperty('TIFilterBlock1', 'State', slotCurrent);
                intensityBlueLED = intensityLedBCECFH;
                stateCube = 'L'; % for the next acquisition
        end
        pause(0.6); prt('Filter Rotated');
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function changeToBurstMode
        modeAcquisition = 'BCECF-burst';
        outputAnalogLED(objDaqAOLEDBlue, intensityBlueLED);
        
                % Start sequence acquisition
                mmc.setCircularBufferMemoryFootprint(100);
                mmc.initializeCircularBuffer();

                mmc.startSequenceAcquisition('Andor1', 100000, 0, false);
                mmc.startSequenceAcquisition('Andor2', 100000, 0, false);
                
        sleep(exposure(1) * 2 + waitAfterLedForBCECF);
        flgEndZ = true;
%         waitAfterDaq = 0;
        waitFrame = 0;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function stopBurst
        mmc.stopSequenceAcquisition('Andor1');
        mmc.stopSequenceAcquisition('Andor2');
        outputAnalogLED(objDaqAOLEDBlue, 0);
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function performPFS
        % Use PFS to focus if the last plane has just acquired
        if flgPFS && ~flgBurstBCECF && (...
                strcmp(modeAcquisition, 'ND') && flgEndZ ||...
                strcmp(modeAcquisition, 'BCECF-ND') && flgEndZ && strcmp(stateCube, 'L')||...
                strcmp(modeAcquisition, 'BCECF') && strcmp(stateCube, 'L') ||...
                strcmp(modeAcquisition, 'discrete') )
            
            sleep(waitPrePFS);
            posZCurrent = mmc.getPosition('TIZDrive');
            
            try
                mmc.setProperty('TIPFSStatus', 'State', 'On');
                sleep(waitPFS);
                mmc.setProperty('TIPFSStatus', 'State', 'Off');
                sleep(waitPFS);
            catch err
                mmc.setPosition('TIZDrive', posZPrevious); % Go back to original position if error
                disp(err);
            end
            posZPrevious = posZCurrent;
        end
        
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function saveImages(vector)
            % Write to Img-3 and Img-4 only if it's infrared mode and the first stack
            if stateIR && strcmp(modeAcquisition, 'ND')
                for ind = 1:2
                    % Write image data to the file
                    writeICE(fidImg(ind + 2), vector(:, ind));
                end
            else
                for ind = 1:2
                    % Write image data to the file
                    writeICE(fidImg(ind), vector(:, ind));
                end
                prt(bframe, 'saved');
            end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function saveImagesND
        if flgFastAcquisition && ~stateIR
            if flgEndZ
                saveImages( reshape(vectorImage, dimY(1)*dimX(1)*numZStack, 2) );
            end
        else
            saveImages( vectorImage(:, frameZ, :) );
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function snapImage
        if ~stateIR
            switch modeExcitation
                case 'xcite'
                    mmc.snapImage();
                case 'LED'
                    outputAnalogLED(objDaqAOLEDBlue, intensityBlueLED);
                    mmc.snapImage();
                    sleep(waitSnap);
                    outputAnalogLED(objDaqAOLEDBlue, 0);
            end
        elseif stateIR
            outputAnalogLED(objDaqAOLEDRed, intensityRedLED);
            mmc.snapImage();
            outputAnalogLED(objDaqAOLEDRed, 0);
        end
        
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function trackByRegistration
        tTrack = tic;
        if all( isnan(imgTrackingTemplateFFT) )
            imgTrackingTemplateFFT = fft2(imgTrackingCurrent);
            prt('Tracking template recorded');
            return
        else    
        [shifts, ~] = dftregistration(imgTrackingTemplateFFT, fft2(imgTrackingCurrent), 1);
%         figure;imagesc(imgTrackingCurrent);
            offsetX = shifts(1, 4);
            offsetY = shifts(1, 3);
            
            moveX = round( offsetX * (sizePixel / magnification) );
            moveY = round(-offsetY * (sizePixel / magnification) );
            
            thorMovRel(objThor, moveX, moveY);
            sleep(waitTracking);
            prt( 'moveX =', moveX, ', moveY =', moveY, shifts(1, 1), shifts(1, 2), ', tTrack =', toc(tTrack) );
        end
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
            st = smOven.Data(21); % Offseted set temperature sent to Oven
            et = tempSet(frame, 2);
            ot = tempObj(frame, 1);
        else
            da = dataTC;
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
        smOven.Data(1) = 1; % always 'on' for now
        
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
            otherwise
                prt('Oven mode not specified:' , mode);
        end
        
        if ~isnan(idx)
            smOven.Data(idx) = value;
            smOven.Data(1) = 1; % ready to parse
        end 
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function readOven
        rTemperature = smOven.Data(31); % temperature
        rVoltage = smOven.Data(32); % voltage
        rOutput = smOven.Data(33); % output
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     function monitorSM
%         nc = bprt('Mr:', smOven.Data(1), 'Or:', smOven.Data(2), 'Sd:', smOven.Data(4), 'sT:', smOven.Data(21), 'sV:', smOven.Data(22), 'sO:', smOven.Data(23), ...
%             'sP:', smOven.Data(24), 'sI:', smOven.Data(25), 'sC:', smOven.Data(26), 'Tm:', smOven.Data(31), 'Vt:', smOven.Data(32), ...
%             'Op:', smOven.Data(33) ,nc);
% 
%     end
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
        switch modeHeater
            case 'TEC'
                if flgEndZ
                    switchCoolHeat;
                    sendTemperature('auto');
                end
                
            case 'laser'
                if flgEndZ % Oven should stay constant
                    switchCoolHeat;
                    sendTemperature('initial');               
                end
                
                vLaser(frame, 1) = offsetTemp(tempSet(frame, 1),...
                    vLaserAtTLaser1, tLaser1, vLaserAtTLaser2, tLaser2);
                
                smZap.Data(5) = false; % Continuous mode on laser controller
                smZap.Data(2) = vLaser(frame, 1);
                smZap.Data(1) = 1;
                
                disp(vLaser(frame, 1));
            case 'zap'
                switchCoolHeat;
                if flgEndZ % Oven should stay constant
                    sendTemperature('initial');                 
                end
                if stateZap && toc(tStart) > planLaser(planIndexLaser, 1)
                    sendLaser('fire');
                    if size(planLaser, 1) < planIndexLaser
                        sendLaser('terminate');
                    end
                end
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function sendLaser(mode)
        switch mode
            case 'initialize' 
                stateZap = true; % intitialize zap state
                planIndexLaser = 1;
                smZap.Data(2) = 0; % Laser output should be 0 at this point
                sleep(100); % Wait for the other MATLAB process to turn off the laser
                smZap.Data(1) = 0; % Triger is set to 'off'
            case 'fire'
                smZap.Data(5) = true; % Pulse mode on laser controller
                smZap.Data(3) = zapDuration;
                smZap.Data(2) = zapPower;
                smZap.Data(1) = 1;
                planIndexLaser = planIndexLaser + 1;
            case 'terminate'
                stateZap = false; % intitialize zap state
                planIndexLaser = 1;
            otherwise
                prt('Wrong laser mode');
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function sendTemperature(mode)
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
            otherwise
                prt('Wrong temperature mode');
                return
        end
        
        sendOven(adjTemp, 'temperature');

    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function controlRamp
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
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function getTimesAndTemperatures

        % Get current times and temperatures
        tempOven(frame, 2) = toc(tStart);
        % tempOven(frame, 1) = share2mat('temperature');
        tempOven(frame, 1) = rTemperature;
        tempDaq(frame, 2) = toc(tStart);
        tempDaq(frame, 1) = dataTC;
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
%             'Marker', 'x', 'MarkerSize', ms);
        handles.plotSet = line(tempSet(:, 2), tempSet(:, 1),...
            'Parent', handles.axisTemperatures, 'Color', [77 225 255]./ 255,...
            'LineStyle', '-', 'LineWidth', lw);
%             'Marker', 'x', 'MarkerSize', ms);
        handles.plotObjective = line(tempObj(:, 2), tempObj(:, 1),...
            'Parent', handles.axisTemperatures, 'Color', [255 153 51]./ 255,...
            'LineStyle', '-', 'LineWidth', lw,...
            'Marker', 'none');
        
        % To speed up the plotting process
        set(handles.plotOven, 'EraseMode', 'none');
        set(handles.plotDaq, 'EraseMode', 'none');
        set(handles.plotSet, 'EraseMode', 'none');
        set(handles.plotObjective, 'EraseMode', 'none');
        
        % static limits of the plots
        xlim(handles.axisTemperatures, [0, duration]);
        
        mi = tempIni - offsetTemp(tempIni, offsetLow, tempLow, offsetHigh, tempHigh);
        ma = tempFin - offsetTemp(tempFin, offsetLow, tempLow, offsetHigh, tempHigh);
        
        if mi < ma
            ylim(handles.axisTemperatures, [mi * 0.8 ma * 1.05]);
        elseif mi > ma
            ylim(handles.axisTemperatures, [ma * 0.8 mi * 1.05]);
        else
            ylim(handles.axisTemperatures, [mi * 0.8 ma * 1.05]);
        end
        setappdata(handles.axisTemperatures, 'LegendColorbarManualSpace', 1);
        setappdata(handles.axisTemperatures, 'LegendColorbarReclaimSpace', 1);
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function updatePlots
        % Update the plots for three temperature measurements This is THE fastest way to plot
        % numbers (use 'EraseMode', 'none' setting in the initial line function).
        
        if frame == 1
            fr = 1;
        else
            fr = framePrevPlot:frame; % line connecting 2 timepoints
        end
        framePrevPlot = frame;
        
        set(handles.plotOven, 'XData', tempOven(fr, 2), 'YData', tempOven(fr, 1));
        set(handles.plotDaq, 'XData', tempDaq(fr, 2), 'YData', tempDaq(fr, 1));
        set(handles.plotSet, 'XData', tempSet(fr, 2), 'YData', tempSet(fr, 1));
        set(handles.plotObjective, 'XData', tempObj(fr, 2), 'YData', tempObj(fr, 1));
        
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
    function switchCoolHeat
        
        switch modeLoop
            case 'run'
                st = tempSet(frame, 1) -...
                    offsetTemp(tempSet(frame, 1), offsetLow, tempLow, offsetHigh, tempHigh);
            case 'walk'
                st = tempIni - offsetTemp(tempIni, offsetLow, tempLow, offsetHigh, tempHigh);
        end
        
        % TEC cool/heat switch
        if (rTemperature > st) && rOutput == 0
            sendOven(1, 'coolheat'); % set it to 'cool'
            set(handles.popupCoolHeat, 'Value', 1);
        elseif(rTemperature < st) && rOutput == 0
            sendOven(2, 'coolheat'); % set it to 'heat'
            set(handles.popupCoolHeat, 'Value', 2);
        end

    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Nested function for initiating rapid cooling
    function initiateRapidCooling
        voltageCool = 10;
        % For rapid cooling after a session
        adjTemp = tempIni - offsetTemp(tempIni, offsetLow, tempLow, offsetHigh, tempHigh);
        if adjTemp < 5
            adjTemp = 5; % don't want to go below safety limit
        end
        sendOven(adjTemp, 'temperature');
        sendOven(voltageCool, 'voltage');
        sendOven(1, 'coolheat');
        set(handles.popupCoolHeat, 'Value', 1);
        stateRapidCooling = true;
        prt('Voltage = ', voltageCool, 'V for rapid cooling');
        if flgPFS && ~mmc.isContinuousFocusEnabled
            togglePFS;
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function checkAndTerminateRapidCooling
        tO = rTemperature;
        iO = tempIni - offsetTemp(tempIni, offsetLow, tempLow, offsetHigh, tempHigh);
        if iO > tO
            if ~stateCountdown
                tCool = tic; % start rapid cooling termination count-down
                stateCountdown = true;
                prt('Counting down to terminate rapid cooling...');
            end
            if toc(tCool) > 5
                sendOven(sVoltage, 'voltage');
                sendOven(2, 'coolheat');
                set(handles.popupCoolHeat, 'Value', 2);
                prt('Voltage = ', sVoltage, 'V for regular control');
                stateRapidCooling = false;
                stateCountdown = false;
            end
        end
    end
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     function endRapidCooling
%         sendOven(sVoltage, 'voltage');
%         sendOven(2, 'coolheat');
%         set(handles.popupCoolHeat, 'Value', 2);
%         prt('Voltage = ', sVoltage, 'V for heating');
%     end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Nested function for saving temperature readings to mat file
    function saveVariables
        % Get rid of rows that are all NaN from the 2D matrices and save them (Vectorized)
        tempSet = tempSet(any(~isnan(tempSet), 2), :);
        tempOven = tempOven(any(~isnan(tempOven), 2), :);
        tempDaq = tempDaq(any(~isnan(tempDaq), 2), :);
        tempObj = tempObj(any(~isnan(tempObj), 2), :);
        infoND = infoND(any(~isnan(infoND), 2), :);
        infoIR = infoIR(any(~isnan(infoIR), 2), :);
        vLaser = vLaser(any(~isnan(vLaser), 2), :);
        numFrames = frame - 1;
        numZStack;
        zapDuration;
        zapPower;
        planLaser;
        flgBurstBCECF;
        flgIntervalBCECF;
        planBCECF;
        status;

        % Save variable that are esential for analysis
        save([strrep(strrep(nameFileICE{1}, '.ice', ''), 'Img-1_', 'Variables_'), '.mat'],...
            'tempDaq', 'tempObj', 'tempOven', 'tempSet', 'Ver',...
            'modeAcquisition', 'modeHeater', 'flgIR', ...
            'modeExcitation', 'intensityLedBCECFL', 'intensityLedBCECFH',...
            'intensityBlueLED', 'intensityRedLED',...
            'numFrames', 'numZStack',...
            'offsetDaq', 'pathFolder', 'titleExperiment', 'exposure', 'gainEM', 'dimX', 'dimY',...
            'tempIni', 'tempFin', 'tempSlope', 'holdIni', 'duration',...
            'sProp', 'sInteg', 'sVoltage', 'sCoolheat', 'sOutput',...
            'offsetLowLow', 'tempLowLow', 'offsetHighLow', 'tempHighLow',...
            'offsetLowHigh', 'tempLowHigh', 'offsetHighHigh', 'tempHighHigh',...
            'vLaserAtTLaser1', 'vLaserAtTLaser2', 'tLaser1', 'tLaser2',...
            'dimZ', 'baseZ', 'stepZ', 'waitStage', 'waitPrePFS', 'waitPFS', 'waitFrame',...
            'vLaser', 'infoND', 'infoIR',...
            'zapDuration', 'zapPower', 'planLaser', 'modulesLaser',...
            'flgBurstBCECF', 'flgIntervalBCECF', 'planBCECF', 'status');
        
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Nested Functions for UI Callbacks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function selectTrackingPlane(~, ~)
        
        cPlanes = str2double(get(handles.popupTrackingPlane, 'String'));
        frameTracking = get(handles.popupTrackingPlane, 'Value');
        selectedZ = cPlanes(frameTracking);
        
        outputAnalogPiezo(objDaqAOPiezo, selectedZ);
        
        % Snap a frame
        modeOriginal = modeAcquisition;
        modeAcquisition = 'discrete';
        sleep(200);
        prepareImages;
        modeAcquisition = modeOriginal;
        
        % Back to z-base
        moveToBaseZ;
        
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Nested callback function for stage control
    function moveStage(~, ~)
        
        if flgEndZ
            posZ = baseZ + (stepZ * 1) - stepZ; % Move back to the first z-plane
        else
            posZ = baseZ + (stepZ * (frameZ + 1)) - stepZ; % Move to the next z-plane
        end
        
        % Move the stage by either controller
        outputAnalogPiezo(objDaqAOPiezo, posZ);
        
        % Wait until the stage settles
        if flgEndZ
            sleep(300);
        else
            sleep(waitStage);
        end
    end
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
            set(handles.fig, 'Position', [1240 posFig(2) posFig(3) posFig(4)]);
            set(handles.pushAlignCameras, 'String', 'Stop');
            modeCamera = 'prePreview';
            modeLoop = 'startWalk';
            flgCameraAlignment = true;
            
            % Create a figure
            handles.figAlignCameras = figure;
            % Alignment figure
            xDimImage = 512;
            yDimImage = 512;
            pos.figAlignCameras     = [100 700 xDimImage*2+50 yDimImage*2+50];
            pos.panelAlignCameras   = [25 25 xDimImage*2 yDimImage*2];
            pos.axisAlignCameras    = [0 0 xDimImage*2 yDimImage*2];
            set(handles.figAlignCameras, 'Units', 'pixels', 'Toolbar', 'figure',...
                'Name', 'Dual Camera Alignment', 'Numbertitle', 'off', 'Position',...
                pos.figAlignCameras, 'Renderer', 'Painters', 'CloseRequestFcn', @endAlignment);
            
            % Create a panel for alignment
            handles.panelCameraAlignment = uipanel('Parent',handles.figAlignCameras, 'Units',...
                'pixels', 'BackgroundColor', get(handles.figAlignCameras, 'Color'), 'Position',...
                pos.panelAlignCameras);
            
            % Create axis for alignment images
            handles.axisAlignCameras = axes('Parent', handles.panelCameraAlignment, 'Units',...
                'pixels', 'FontName', fn, 'FontSize', fs, 'Position', pos.axisAlignCameras,...
                'Layer','top');
            set(handles.axisAlignCameras, 'XTick', [], 'YTick', []);
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
    function setEmGain(~, ~)
        gainEM(1) = str2double(get(handles.editEmGainR, 'String'));
        gainEM(2) = str2double(get(handles.editEmGainG, 'String'));
        mmc.setProperty('Andor1', 'Gain', gainEM(1));
        mmc.setProperty('Andor2', 'Gain', gainEM(2));
        if ~flgCameraAlignment
            handles.jFig.getAxisComponent.requestFocus;
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function setExposures(~, ~)
        exposure(1) = str2double(get(handles.editExposureR, 'String'));
        exposure(2) = str2double(get(handles.editExposureG, 'String'));
        
        % Java error if exposure is changed without this line
        mmc.setExposure(exposure(1));
        
        mmc.setProperty('Andor1', 'Exposure', exposure(1));
        mmc.setProperty('Andor2', 'Exposure', exposure(2));
        mmc.getProperty('Andor1', 'Exposure');
        mmc.getProperty('Andor2', 'Exposure');
        if ~flgCameraAlignment
            handles.jFig.getAxisComponent.requestFocus;
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function toggleLED(~, ~)
        
        switch modeExcitation
            case 'xcite'
                sh = mmc.getShutterOpen();
                if sh
                    mmc.setShutterOpen(0);
                else
                    mmc.setShutterOpen(1);
                end
            case 'LED'
                if flgShutterState == 1
                    outputAnalogLED(objDaqAOLEDBlue, 0);
                    flgShutterState = 0;
                    set(handles.pushToggleLED, 'String', 'LED On');
                elseif flgShutterState == 0
                    outputAnalogLED(objDaqAOLEDBlue, intensityBlueLED);
                    flgShutterState = 1;
                    set(handles.pushToggleLED, 'String', 'LED Off');
                end
        end
        handles.jFig.getAxisComponent.requestFocus;
        
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function setIntensityLED(~, ~)
        intensityBlueLED = str2double(get(handles.editIntensityLED, 'String'));
        if ~isscalar(intensityBlueLED) || ~isnumeric(intensityBlueLED) ||...
                isnan(intensityBlueLED)
            disp('Must be numeric scalar');
            return
        end
        switch modeExcitation
            case 'xcite'
                if intensityBlueLED > 100
                    intensityBlueLED = 100;
                elseif intensityBlueLED < 0
                    intensityBlueLED = 0;
                end
                mmc.setProperty('XCite-Exacte', 'Lamp-Intensity', intensityBlueLED);
            case 'LED'
                if intensityBlueLED > 5
                    intensityBlueLED = 5;
                elseif intensityBlueLED < 0
                    intensityBlueLED = 0;
                end
        end
        handles.jFig.getAxisComponent.requestFocus;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function togglePFS(~, ~)
        p = mmc.isContinuousFocusEnabled();
        if p
            mmc.enableContinuousFocus(0);
            set(handles.pushPFS, 'String', 'PFS On');
        else
            mmc.enableContinuousFocus(1);
            set(handles.pushPFS, 'String', 'PFS Off');
        end
        
        handles.jFig.getAxisComponent.requestFocus;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function moveToBaseZ(~, ~)
        baseZ = str2double(get(handles.editBaseZ, 'String'));
        outputAnalogPiezo(objDaqAOPiezo, baseZ);
        handles.jFig.getAxisComponent.requestFocus;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function setBaseZ(~, ~)
        baseZ = str2double(get(handles.editBaseZ, 'String'));
        setTrackingPlanes;
        handles.jFig.getAxisComponent.requestFocus;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function setDimZ(~, ~)
        dimZ = str2double(get(handles.editDimZ, 'String'));
        numZStack = ceil(dimZ / stepZ);
        setTrackingPlanes;
        handles.jFig.getAxisComponent.requestFocus;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function setStepZ(~, ~)
        stepZ = str2double(get(handles.editStepZ, 'String'));
        numZStack = ceil(dimZ / stepZ);
        setTrackingPlanes;
        handles.jFig.getAxisComponent.requestFocus;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function setWaits(~, ~)
        waitFrame = str2double(get(handles.editWaitFrame, 'String'));
        handles.jFig.getAxisComponent.requestFocus;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function setFlgPFS(~, ~)
        flgPFS = get(handles.checkUsePFS, 'Value');
        handles.jFig.getAxisComponent.requestFocus;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function setFlgTracking(~, ~)
        flgTracking = get(handles.checkEnableTracking, 'Value');
        handles.jFig.getAxisComponent.requestFocus;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function setFlgIR(~, ~)
        flgIR = get(handles.checkEnableIR, 'Value');
        handles.jFig.getAxisComponent.requestFocus;
        if flgIR
            dimX(1:4) = 512;
            dimY(1:4) = 512;
        else
            dimX(1:2) = 512;
            dimY(1:2) = 512;
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function setFlgDisplayAllFrames(~, ~)
        flgDisplayAllFrames = get(handles.checkEnableDisplayAllFrames, 'Value');
        handles.jFig.getAxisComponent.requestFocus;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function setFastAcquisition(~, ~)
        flgFastAcquisition = get(handles.checkFastAcquisition, 'Value');
        handles.jFig.getAxisComponent.requestFocus;        
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function setFlgRequestAnalysis(~, ~)
        flgRequestAnalysis = get(handles.checkRequestAnalysis, 'Value');
        handles.jFig.getAxisComponent.requestFocus;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function setLaserVariables(~, ~)
        zapPower = str2double(get(handles.editPowerLaser, 'String'));
        waitInitialLaser = str2double(get(handles.editWaitInitialLaser, 'String'));
        waitFinalLaser = str2double(get(handles.editWaitFinalLaser, 'String'));
        intervalLaser = str2double(get(handles.editIntervalLaser, 'String'));
        zapDuration = str2double(get(handles.editDurationLaser, 'String'));
        repeatLaser = str2double(get(handles.editRepeatLaser, 'String'));
        modulesLaser = str2double(get(handles.editModulesLaser, 'String'));
        
        makeZapPlan;
        makeExperimentTitle;
        updateStaticUIComponents;
        handles.jFig.getAxisComponent.requestFocus;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function setBCECFVariables(~, ~)
        intensityLedBCECFL = str2double(get(handles.editIntensityBCECFL, 'String'));
        intensityLedBCECFH = str2double(get(handles.editIntensityBCECFH, 'String'));
        waitInitialBCECF = str2double(get(handles.editWaitInitialBCECF, 'String'));
        waitFinalBCECF = str2double(get(handles.editWaitFinalBCECF, 'String'));
        intervalBCECF = str2double(get(handles.editIntervalBCECF, 'String'));
        flgBurstBCECF = get(handles.checkEnableBurstBCECF, 'Value');
        flgIntervalBCECF = get(handles.checkIntervalBCECF, 'Value');
        makeBCECFPlan;
        updateStaticUIComponents;
        handles.jFig.getAxisComponent.requestFocus;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function setRampVariables(~, ~)
        holdIni = str2double(get(handles.editWaitInitialRamp, 'String'));
        duration = str2double(get(handles.editDurationRamp, 'String'));
        tempIni = str2double(get(handles.editTemperatureInitial, 'String'));
        tempFin = str2double(get(handles.editTemperatureFinal, 'String'));

        switch modeHeater
            case 'zap'
                makeZapPlan;
        end
        switch modeAcquisition
            case 'BCECF'
                makeBCECFPlan;
        end
        makeExperimentTitle;
        updateStaticUIComponents;
        handles.jFig.getAxisComponent.requestFocus;
    end
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     function nnn(~, ~)
%         nnn = get(handles.nnn, 'Value');
%         handles.jFig.getAxisComponent.requestFocus;
%     end

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
        numFrames = duration * 30;
        
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
    function clickImage(~, ~)
        if exist('hPoint', 'var')
            if ~isnan(hPoint) && ishghandle(hPoint)
                delete(hPoint);
                clear('hPoint');
                hPoint = nan;
            end
        end
        cp = get(gca, 'CurrentPoint');
        posY = cp(1, 2);
        posX = cp(1, 1);
        
        hold on
        hPoint = plot(posX, posY, 'r+', 'Parent', gca);
        hold off
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
        
        if issafe('tmr')
            stop(tmr);
        end
        
        if exist('smOven', 'var')
            % Stop Oven
            smOven.Data(4) = 1;
            prt('Closing processOven...');
        end

        if exist('smZap', 'var')
            % Stop laser output
            smZap.Data(2) = 0;
            sleep(100); % Wait for the other instance to turn of the laser
            smZap.Data(1) = 0;

            % sending stop signal to other instance
            smZap.Data(4) = 1;
            prt('Closing processZap...');
        end
        
        fclose('all'); % close all open files

        if issafe('hListnDaqTC')
            delete(hListnDaqTC);
            prt('TC listner terminated');
        end
        
        if issafe('objDaqAOPiezo')
            objDaqAOPiezo.stop();
            objDaqAOPiezo.release();
            delete(objDaqAOPiezo);
            prt('Piezo terminated');
        end          

        if issafe('objDaqAI') 
            delete(objDaqAI);
            prt('Daq terminated');
        end

        if issafe('objThor')
            fclose(objThor);
            delete(objThor);
            clear objThor;
            prt('Thor terminated');
        end

        if issafe('objDaqAOLEDRed')
            objDaqAOLEDRed.stop();
            objDaqAOLEDRed.release();
            delete(objDaqAOLEDRed);
            clear objDaqAOLEDRed;
            prt('Red LED terminated');
        end
        
        if issafe('objDaqAOLEDBlue')
            objDaqAOLEDBlue.stop();
            objDaqAOLEDBlue.release();
            delete(objDaqAOLEDBlue);
            clear objDaqAOLEDBlue;
            prt('Blue LED terminated');
        end
        
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
    function pushDataAI(~, event)

        temp = event.Data;
        dataOB = temp(end, 1);
        %         prt(dataTC);
        dataV = temp(end, 2) * 1.0056;
        dataTC = temp(end, 3) + offsetDaq;

    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function endAlignment(~, ~)
        toggleAlign;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Nested Functions for Initializations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function initiateMatlabProcesses
        % Create shared memory for a new process of MATLAB (laser zapping)
        if ~isobject(smZap)
            smZap = createSharedMemory( smZap, 'memZap.dat', zeros(6, 1) );
        end
        
        % Create shared memory for a new process of MATLAB (serial communication)
        if ~isobject(smOven)
            ovenInitial = zeros(64, 1);
            ovenInitial(21) = tempIni - offsetTemp(tempIni, offsetLow, tempLow, offsetHigh, tempHigh);
            ovenInitial(22) = sVoltage;
            ovenInitial(23) = sOutput;
            ovenInitial(24) = sProp;
            ovenInitial(25) = sInteg;            
            ovenInitial(26) = sCoolheat;
            ovenInitial(4) = 0; % self-destruct sequence
            
            smOven = createSharedMemory(smOven, 'memSerial.dat', ovenInitial);
        end
        
        % Check how many processes of MATLAB running
        [~,result] = system('tasklist /FI "imagename eq matlab.exe" /fo table /nh');
        
        % If there is only one process, then create two more
        if numel(strfind(result, 'MATLAB.exe')) == 1
            % Call another instance of MATLAB for serial communication -nodesktop -minimize 
            system('matlab -nosplash -nodesktop -minimize -r processZap &');
            % Call another instance of MATLAB for serial communication
            system('matlab -nosplash -nodesktop -minimize -r processOven &');

        else
            figureTermination;
            error('Close other MATLAB processes first');
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function memoryShared = createSharedMemory(memoryShared, nameFile, initialMatrix)
        
        % Create shared memory for a new process of MATLAB (serial communication)
        if ~isobject(memoryShared)
            pathFile = fullfile(tempdir, nameFile);
            
            % Create the communication file if it is not already there.
            if ~exist(pathFile, 'file')
                [fid, msg] = fopen(pathFile, 'wb');
                if fid == -1
                    error('MATLAB:acquireICE:cannotOpenFile',...
                        'Cannot open file "%s": %s.', pathFile, msg);
                end
                fwrite(fid, initialMatrix, 'double'); fclose(fid);
            end
            
            memoryShared = memmapfile(pathFile, 'Writable', true, 'Format', 'double');
            
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function initDaqAI()
        
        % Initialize DAQ for analogue input (TC and voltage)
        
        warning off; %#ok<WNOFF>
        objDaqAI = daq.createSession('ni');
        
        objOB = objDaqAI.addAnalogInputChannel('cDAQ1Mod2', 'ai0', 'Thermocouple');
        objAI = objDaqAI.addAnalogInputChannel('cDAQ1Mod2', 'ai2', 'Voltage');
        objTC = objDaqAI.addAnalogInputChannel('cDAQ1Mod2', 'ai3', 'Thermocouple');
        
        objTC.ThermocoupleType = 'T';
        objTC.Units = 'Celsius';
        
        objOB.ThermocoupleType = 'T';
        objOB.Units = 'Celsius';
        
        objTC.ADCTimingMode = 'HighSpeed';
        objAI.ADCTimingMode = 'HighSpeed';
        objOB.ADCTimingMode = 'HighSpeed';
        
        objDaqAI.Rate = 20;
        
        objDaqAI.IsContinuous = true;
        
        disp(objTC);
        disp(objAI);
        disp(objOB);
        
        warning on; %#ok<WNON>
        
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function initDaqAOPiezo()
        objDaqAOPiezo = daq.createSession('ni');
        objDaqAOPiezo.addAnalogOutputChannel('cDAQ1Mod3', 'ao0', 'Voltage');
        objDaqAOPiezo.Rate = 10000;
        
        outputAnalogPiezo(objDaqAOPiezo, 0);
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function initDaqAOLED()
        objDaqAOLEDBlue = daq.createSession('ni');
        objDaqAOLEDBlue.addAnalogOutputChannel('cDAQ1Mod3', 'ao3', 'Voltage');
        objDaqAOLEDBlue.Rate = 10000;
        
        outputAnalogLED(objDaqAOLEDBlue, 0);
        
        objDaqAOLEDRed = daq.createSession('ni');
        objDaqAOLEDRed.addAnalogOutputChannel('cDAQ1Mod3', 'ao2', 'Voltage');
        objDaqAOLEDRed.Rate = 10000;
        
        outputAnalogLED(objDaqAOLEDRed, 0);
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function initThor()
        objThor = serial('COM8', 'BaudRate', 115200);
        sleep(2000);
        fopen(objThor);
        get(objThor);
        
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function resetInitialVariableValues
        frame = 1;
        frameZ = 1;
        bframe = 0;
        stateFinishedIR = 0;
        tPrev = nan;
        skipInitialHold = 1;
        vectorImage = zeros(dimY(1) * dimX(1), numZStack, 2, 'uint16');
        imgTrackingCurrent = nan(dimY(1), dimX(1));
        imgTrackingTemplateFFT = nan(dimY(1), dimX(1));
        frameTracking = get(handles.popupTrackingPlane, 'Value');
        
        tempOven = nan(numFrames, 2);
        tempDaq = nan(numFrames, 2);
        tempObj = nan(numFrames, 2);
        tempSet = nan(numFrames, 2);
        infoND = nan(numFrames, 5);
        infoIR = nan(numFrames, 5);
        vLaser = nan(numFrames, 1);
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function setInitialValuesForTemperatureControl

            % Set the voltage back to default
            sendOven(sVoltage, 'voltage');
            
            % Set laser power to zero
            switch modeHeater
                case 'zap'
                    smZap.Data(2) = 0;
                    sleep(100); % Wait for the other instance to turn of the laser
                    smZap.Data(1) = 0;
            end
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
            case 'n'
                set(handles.popupModeAcquisition, 'Value', 2);
                updateVariablesForSelectedAcquisitionMode(handles.popupModeAcquisition);
            case 'a'
                toggleAcquisition;
            case 'l'
                toggleAlign;
            case 'f'
                togglePFS;
            case 'd'
                toggleLED;
            case 'downarrow'
                strPopup = get(handles.popupTrackingPlane, 'String');
                dimPopup = size(strPopup, 1);
                
                val = get(handles.popupTrackingPlane, 'Value');
                val = val + 1;
                if val > dimPopup
                    val = dimPopup;
                end
                set(handles.popupTrackingPlane, 'Value', val)
                selectTrackingPlane;
            case 'uparrow'
                val = get(handles.popupTrackingPlane, 'Value');
                val = val - 1;
                if val < 1
                    val = 1;
                end
                set(handles.popupTrackingPlane, 'Value', val)
                selectTrackingPlane;                
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% GUI Components
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Nested Functions for creating GUI components
    function createGUI
        % Get a path of this m-file
        [pathM, ~, ~] = fileparts(mfilename('fullpath'));
        
        handles = loadGUI([pathM, '\acquireICE.fig']);

        % For a compatibility reason
        handles.axisImages(1) = handles.axisImagesR;
        handles.axisImages(2) = handles.axisImagesG;
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
        set(handles.editEmGainR, 'Callback', @setEmGain);
        set(handles.editEmGainG, 'Callback', @setEmGain);
        set(handles.pushToggleLED, 'Callback', @toggleLED);
        set(handles.editIntensityLED, 'Callback', @setIntensityLED);
        set(handles.popupModeAcquisition, 'Callback', @updateVariablesForSelectedAcquisitionMode);
        set(handles.pushPFS, 'Callback', @togglePFS);
        set(handles.pushMoveToBaseZ, 'Callback', @moveToBaseZ);
        set(handles.editBaseZ, 'Callback', @setBaseZ);
        set(handles.editDimZ, 'Callback', @setDimZ);
        set(handles.editStepZ, 'Callback', @setStepZ);
        set(handles.editWaitFrame, 'Callback', @setWaits);
        set(handles.popupModeHeater, 'Callback', @updateVariablesForSelectedHeaterMode);
        set(handles.pushPreview, 'Callback', @togglePreview);
        set(handles.pushAcquire, 'Callback', @toggleAcquisition);
        set(handles.pushAlignCameras, 'Callback', @toggleAlign);
        set(handles.popupTrackingPlane, 'Callback', @selectTrackingPlane);
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
        
        set(handles.checkUsePFS, 'Callback', @setFlgPFS);
        set(handles.checkEnableTracking, 'Callback', @setFlgTracking);
        set(handles.checkEnableIR, 'Callback', @setFlgIR);
        set(handles.checkEnableDisplayAllFrames, 'Callback', @setFlgDisplayAllFrames);
        set(handles.checkFastAcquisition, 'Callback', @setFastAcquisition);        
        set(handles.checkRequestAnalysis, 'Callback', @setFlgRequestAnalysis);
        
        set(handles.editPowerLaser, 'Callback', @setLaserVariables);
        set(handles.editWaitInitialLaser, 'Callback', @setLaserVariables);
        set(handles.editWaitFinalLaser, 'Callback', @setLaserVariables);
        set(handles.editIntervalLaser, 'Callback', @setLaserVariables);
        set(handles.editDurationLaser, 'Callback', @setLaserVariables);
        set(handles.editRepeatLaser, 'Callback', @setLaserVariables);
        set(handles.editModulesLaser, 'Callback', @setLaserVariables);
        
        set(handles.editIntensityBCECFL, 'Callback', @setBCECFVariables);
        set(handles.editIntensityBCECFH, 'Callback', @setBCECFVariables);
        set(handles.editWaitInitialBCECF, 'Callback', @setBCECFVariables);
        set(handles.editWaitFinalBCECF, 'Callback', @setBCECFVariables);
        set(handles.editIntervalBCECF, 'Callback', @setBCECFVariables);
        set(handles.checkEnableBurstBCECF, 'Callback', @setBCECFVariables);
        set(handles.checkIntervalBCECF, 'Callback', @setBCECFVariables);
        
        set(handles.editWaitInitialRamp, 'Callback', @setRampVariables);
        set(handles.editDurationRamp, 'Callback', @setRampVariables);

%         set(handles.nnn, 'Callback', @nnn);
%         set(handles.nnn, 'Callback', @nnn);
        

    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function updateStaticUIComponents
   
        % Set values and strings of the UI components
        set(handles.fig, 'Name', ['acquireICE ', Ver]);
        set(handles.fig, 'MenuBar', 'none');
        set(handles.fig, 'ToolBar', 'none');
        set(handles.editPathFolder, 'String', pathFolder);
        set(handles.editTitle, 'String', titleExperiment);
        set(handles.editExposureR, 'String', exposure(1));
        set(handles.editExposureG, 'String', exposure(2));
        set(handles.editEmGainR, 'String', gainEM(1));
        set(handles.editEmGainG, 'String', gainEM(2));
        set(handles.editIntensityLED, 'String', intensityBlueLED);
        set(handles.editWaitFrame, 'String', waitFrame);
        set(handles.editBaseZ, 'String', baseZ);
        set(handles.editDimZ, 'String', dimZ);
        set(handles.editStepZ, 'String', stepZ);
        set(handles.editWaitFrame, 'String', waitFrame);
        set(handles.editTemperatureInitial, 'String', tempIni);
        set(handles.editTemperatureFinal, 'String', tempFin);
        set(handles.editSlopeTemperature, 'String', tempSlope);
        set(handles.editWaitInitialRamp, 'String', holdIni);
        set(handles.editDurationRamp, 'String', duration);
        set(handles.checkSaveRamp, 'Value', enableSave);
        set(handles.editProportional, 'String', sProp);
        set(handles.editIntegral, 'String', sInteg);
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
        
        set(handles.editPowerLaser, 'String', zapPower);
        set(handles.editWaitInitialLaser, 'String', waitInitialLaser);
        set(handles.editWaitFinalLaser, 'String', waitFinalLaser);
        set(handles.editIntervalLaser, 'String', intervalLaser);
        set(handles.editDurationLaser, 'String', zapDuration);
        set(handles.editPlanLaser, 'String', mat2str(planLaser),...
                                   'TooltipString', mat2str(planLaser));
        set(handles.editRepeatLaser, 'String', repeatLaser);
        set(handles.editModulesLaser, 'String', modulesLaser);
        
        set(handles.editIntensityBCECFL, 'String', intensityLedBCECFL);
        set(handles.editIntensityBCECFH, 'String', intensityLedBCECFH);
        set(handles.editWaitInitialBCECF, 'String', waitInitialBCECF);
        set(handles.editWaitFinalBCECF, 'String', waitFinalBCECF);
        set(handles.editIntervalBCECF, 'String', intervalBCECF);
        set(handles.editPlanBCECF, 'String', mat2str(planBCECF),...
                                   'TooltipString', mat2str(planBCECF));
        set(handles.checkEnableBurstBCECF, 'Value', flgBurstBCECF);
        set(handles.checkIntervalBCECF, 'Value', flgIntervalBCECF);
        
        set(handles.checkUsePFS, 'Value', flgPFS);
        set(handles.checkEnableTracking, 'Value', flgTracking);
        set(handles.checkEnableIR, 'Value', flgIR);
        set(handles.checkEnableDisplayAllFrames, 'Value', flgDisplayAllFrames);
        set(handles.checkFastAcquisition, 'Value', flgFastAcquisition);        
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
        modeHeater = dc.popupModeHeater.list{dc.popupModeHeater.last};
        
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
        modeHeater = dc.popupModeHeater.list{val};
        
        updateVariablesForSelectedModes;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function updateVariablesForSelectedModes

        switch modeHeater
            case 'zap' % For all zaps
                
                % ramp variables
                tempIni = 23;
                tempFin = 23;
                tempSlope = 0.05; % PFS starts to fail at faster rate above ~30C
                holdIni = 100;
                duration = 500;
                
                flgIntervalBCECF = false;
                
                % BCECF variables
                waitInitialBCECF = nan;
                intervalBCECF = nan;
                waitFinalBCECF = nan;
                planBCECF = nan;
                intensityLedBCECFL = nan;
                intensityLedBCECFH = nan;
                stateBCECF = false;

%                 threshHeatCool = 10; % Constant heat for lazer zapping assays
                
                switch modeAcquisition
                    case 'BCECF' % For zap & BCECF
                        % BCECF variables
                        zapDuration = 100; % Duration of zapping in milliseconds
                        flgBurstBCECF = true;
                        intensityLedBCECFL = 3;
%                         intensityLedBCECFH = 0.2;
                        intensityLedBCECFH = 2;
                        waitFrame = 0;
                        % laser variables
                        waitInitialLaser = 10;
                        waitFinalLaser = 15;
                        intervalLaser = 5;
                        repeatLaser = 4;
                        modulesLaser = 1;
                    case 'BCECF-ND' % for BCECF-ND acuistion
                        zapDuration = 100; % Duration of zapping in milliseconds
                        intensityLedBCECFL = 3;
                        intensityLedBCECFH = 2;
                    otherwise % zap non-BCECF
                        zapDuration = 20000; % Duration of zapping in milliseconds
                        waitInitialLaser = 50;
                        waitFinalLaser = 50;
                        intervalLaser = 50;
                        repeatLaser = 5;
                        modulesLaser = 1;
                end

                % laser variables
                zapPower = 100; % Power of zapping laser in mA
%                 stateZap = true;                
                planIndexLaser = 1;
                
                makeZapPlan;
                
                % ramp variables
                tempIni = 23;
                tempFin = 28;
                tempSlope = 0;
                   
            otherwise % For all non-zap
                flgBurstBCECF = false;
                
                % ramp variables
                tempIni = 23;
                tempFin = 28;
                tempSlope = 0.05; % PFS starts to fail at faster rate above ~30C
                holdIni = 50;
                duration = 250;
                
%                 tempIni = 23;
%                 tempFin = 28;
%                 tempSlope = 0.033;
%                 holdIni = 100;
%                 duration = 350;
                
                % laser variables
                zapPower = nan;
                planLaser = nan;
                zapDuration = nan;
                waitInitialLaser = nan;
                waitFinalLaser = nan;
                intervalLaser = nan;
                repeatLaser = nan;
                modulesLaser = nan;
%                 stateZap = false;

%                 threshHeatCool = 11.3; % when tempIni is 17C and coolant temperature is 14C.
%                 threshHeatCool = 16.2; % When tempIni is 20C and coolant temperature is 14C.

                switch modeAcquisition
                    case 'BCECF' % For non-zap & BCECF
                        
                        % BCECF variables
                        flgIntervalBCECF = true;
                        waitInitialBCECF = 5;
                        intervalBCECF = 5;
                        waitFinalBCECF = 5;
%                         durationBCECF = duration - waitFinalBCECF - waitInitialBCECF;
                        makeBCECFPlan;
                        
                        planIndexBCECF = 1;
                        stateBCECF = true;
%                         intensityLedBCECFL = 1.2;
%                         intensityLedBCECFH = 0.2;
                        
                        
                        intensityLedBCECFL = 3;
                        intensityLedBCECFH = 2;
                        
                    case 'BCECF-ND' % for BCECF-ND acuistion
                        intensityLedBCECFL = 3;
                        intensityLedBCECFH = 2;     
                    otherwise % For non-zap & non-BCECF 
                        
                        waitInitialBCECF = nan;
                        intervalBCECF = nan;
                        waitFinalBCECF = nan;
                        planBCECF = nan;
                        intensityLedBCECFL = nan;
                        intensityLedBCECFH = nan;
                        stateBCECF = false; % For non-zap BCECF
                end
        end

        switch modeHeater % For laser-ramp specific
            case 'laser'
                disp(['Laser output(L) = ', num2str(vLaserAtTLaser1), ' @ ', num2str(tLaser1), 'C']);
                disp(['Laser output(H) = ', num2str(vLaserAtTLaser2), ' @ ', num2str(tLaser2), 'C']);
        end
        
        switch modeAcquisition % For variables regardless of zap or non-zap
            case 'burst'
%                 waitAfterDaq = 0;
                waitFrame = 0;
                exposure(1) = 10;
                exposure(2) = 10;
                flgPFS = false;
                flgTracking = false;
                flgIR = false;
                flgDisplayAllFrames = true;
                flgFastAcquisition = false;
                flgRequestAnalysis = true;
                intensityBlueLED = 0.2;
                gainEM(1) = 20;
                gainEM(2) = 80;
            case 'ND'
%                 waitAfterDaq = 0;
                waitFrame = 0;
                exposure(1) = 10;
                exposure(2) = 10;
                flgPFS = true;
                flgTracking = true;
                flgIR = true;
                flgDisplayAllFrames = false;
                flgFastAcquisition = true;
                flgRequestAnalysis = true;
                intensityBlueLED = 0.2;
                gainEM(1) = 20;
                gainEM(2) = 80;
            case 'discrete'
                %                 waitAfterDaq = 100;
                waitFrame = 0;
                exposure(1) = 20;
                exposure(2) = 20;
                flgPFS = false;
                flgTracking = false;
                flgIR = true;
                flgDisplayAllFrames = true;
                flgFastAcquisition = false;
                flgRequestAnalysis = true;
                intensityBlueLED = 1;
                gainEM(1) = 5;
                gainEM(2) = 40;
            case {'BCECF', 'BCECF-ND'}
                %                 waitAfterDaq = 100;
                waitFrame = 0;
                exposure(1) = 10;
                exposure(2) = 10;
                flgPFS = false;
                flgTracking = false;
                flgIR = false;
                flgDisplayAllFrames = true;
                flgFastAcquisition = false;
                flgRequestAnalysis = false;
                gainEM(1) = 5;
                gainEM(2) = 40;
        end
        
        switch modeAcquisition
            case {'ND', 'BCECF-ND'}
                dimZ = 26;
                stepZ = 2;
            otherwise
                dimZ = 1;
                stepZ = 1;
        end
        numZStack = ceil(dimZ / stepZ);
        
        if flgIR
            dimX(1:4) = 512;
            dimY(1:4) = 512;
        else
            dimX(1:2) = 512;
            dimY(1:2) = 512;
        end
        
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
        switch modeHeater
            case 'TEC'
                titleExperiment = [nameSample, '_@', tempCultivation, 'C_',...
                    num2str(tempIni), '-', num2str(tempFin), '_', num2str(duration), 's',...
                    '_300um-1P-aga_', lensObjective];
            case 'zap'
                titleExperiment = [nameSample, '_@', tempCultivation, 'C_',...
                    modeHeater, '-', num2str(zapPower), 'mA-', num2str(zapDuration),...
                    'ms_300um-1P-aga_', lensObjective];
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function makeZapPlan
        durationLaser = ( intervalLaser * (repeatLaser - 1) ) + waitInitialLaser;
        planLaser = (waitInitialLaser:intervalLaser:durationLaser)';
        duration = durationLaser + waitFinalLaser;
        holdIni = duration;
        if modulesLaser > 1
            lenModule = duration;
            planLaserOriginal = planLaser;
            for m = 2:modulesLaser
                if isodd(m)
                    planLaserMod = planLaserOriginal + lenModule * (m - 1);
                    planLaser = [planLaser; planLaserMod];
                end
            end
            duration = duration * modulesLaser;
            holdIni = duration;
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function makeBCECFPlan
        planBCECF = waitInitialBCECF:intervalBCECF:duration - waitFinalBCECF;
%         holdIni = duration;
    end
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


