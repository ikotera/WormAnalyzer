function msg = displayICE(arginPath, flgGUI, command, flgWI, handlesWI, tWI, threshSeed)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                      nameFunction = 'displayICE';                    %
                               ver = '0.06';                          %
%                     Aug. 09, 2014 by Ippei Kotera                   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% v0.06 New GUI with separate image window. Support for 2024x2024 image format. Menu-based commands.
% Integration of behavioral analysis. (150207, Ippei Kotera)
%
% v0.05 displayICE overhauled from Jimmy's variable_analysis4
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Initial Variables
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
% Initial values
flgProfile = false;                         % For performance profiling
if ~exist('flgGUI', 'var')
    flgGUI = true;                          % Default GUI mode
end
if ~exist('command', 'var')
    command = 'none';
end
msg = [];
smallScreen = false;                            % Window size
poolsize = 8;                               % Pool size for matlabpool (number of threads to be used)
dirCount = 'C:\count';                      % Temporal directory for counting iteration during parfor
weightDisplay = 0.033;                      % Will be overwritten by adjustDisplayTiming
sG.modeImage = 'uint16';                    % Image data handling for display (uint16, RAM, or map)
sG.safeWheel = false;
modeImageTrack = 'uint16';                  % For tracking calculations (uint16, RAM, or Map)
modeIR = 0;                                 % If the data includes infrared images
modeICE = []; isbehavior = false;
crop_size_r = 10 * 2 + 1;                   % Crop size of tracking
crop_size_c = 10 * 2 + 1;                   % Crop size of tracking
crop_size_z = 1 * 2 + 1;                    % Crop size of tracking
RGB = [2200, 10; 3500, 100; 6996, 100];     % [Rmax, Rmin; Gmax, Gmin; Bmax, Bmin] for image display
colorSelectedPointEdge = 'g';               % Color of selected point
colorSelectedPointFace = 'b';               % Color of the edge of selected point
colorPointsEdge = 'r';                      % Color of tracked points
colorPointsFace  = 'g';                     % Color of the edge of tracked points
flgDataModified = false;
depthColor = [16, 16; 16, 16; 16, 16];

% Preallocation of variables 
isDispayReady = false;
imgRAM{1} = nan; imgRAMMIP{1} = nan;
imgMap{3} = []; imgMapMIP{3} = [];
pathICE{1} = []; pathICEMX{1} = [];
fid = []; fidMIP = [];
pathVar = [];
pathFolder = [];
nameFile = [];
numCh = nan;
numChDisp = nan;
valZ = [];
valT = [];
dimY = [];
dimX = [];
dimZ = [];
dimT = [];
dimTP = [];
dimN = [];
dimC = 2;
dimDispY = [];
dimDispX = [];
ND{1} = []; flgMIP = false;
sVar = [];
hVL = [];
hVLT = [];
hVLB = [];
maxIntens = [];
intensity_ratio = [];                       % Intensity ratio plots
neurons = [];                               % Contains data for neurons
neuronsMip = [];
% z_list = [];                              % List for z-levels; Added 140116
listNeurons = [];                           % List for neurons
nc = 0;
nr = 0;
flgAddNeuron = false;                       % Indicates that the user is currently adding a neuron
flgAddWorm = false;
flgAddBehaviors = false;
worms = [];
idxWorm = 1;
% beh = [];
hFigBeh = [];
hAxisBeh = [];
hLines = [];
maskROI = false(dimX, dimY);
intensityMean = [];
GVF_dx = [];                                % Gradient vector
GVF_dy = [];
hImage = [];                                % Handle for the image
hMask = [];                                 % Handle for mask boundary
hQuiver = [];                               % Handle for gradient vector field
hSelPoint = [];                             % Handle for the selected point
hPoints = [];
hLabels{1} = [];
hFunctions = [];
labels = [];
labelsPrev = [];
sH.statusBar = [];                          % Handle for status bar
sH.progressBar = [];
sH.movingBar = [];
sH.sliderT = [];                        % Slider for time
sH.jScrollBarZ = [];                        % Slider for z-level
sH.jSliderRGB{1} = [];
sH.figTS = [];
sH.ROI = [];
sH.textBehavior = [];
sH.textModeBehavior = [];
sG = [];
sG.dragzoom = false;
% sG.modeImage = modeImage;
sG.showControlPanel = false;
sG.enableMouseMove = true;
sG.enableScrollByMouse = false;
sG.applyFilter = false;
sG.scrollPointer = false;
sG.showBehaviorPanel = false;
filters = [];
sHCtrl.figCtrl = [];
eDisp = nan;
frameSkip = 0;
frameWait = 0;

posX = nan;
posY = nan;
img16 = [];
img = [];
intensityR = nan;
intensityG = nan;
intensityB = nan;
rangeDefaultX = nan;
rangeDefaultY = nan;
rangeX = nan;
rangeY = nan;

[path, ~, ~] = fileparts(which(mfilename)); % Get the path of the m-file executing
paths.iconChecked = [path, '\library\icons\checked.png'];
paths.iconUnchecked = [path, '\library\icons\unchecked.png'];
paths.iconEmpty = [path, '\library\icons\empty.png'];

tTest = tic;
tScroll = tic;                              % Time since last scrolling
isscrolling = false;
scrollAccumulation = 0;
coords = [0,0];
widthWin = nan;
timerObj = [];

% jF = []; jLabel = [];   
declareFunctionHandle;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Main
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if flgGUI
    createGUI;
    if exist('arginPath', 'var')            % If filepath given
        parsePath(arginPath);
        initialize(arginPath);
        loadLabels
        initializeOverlays
        isDispayReady = true;
        displayImage
    end
    associateCallbacks;
end

runOptionCommand;
sG.safeWheel = true;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Profiling Display Performance
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if flgProfile
    openFile; %#ok<UNRCH>
%     set(gcf, 'Renderer', 'painters');
    drawnow;
    selectMenu([], [], '&Layers', '&Red');                  % Default image mode
    autoscaleRGB
    profile on
    tic
    for valT = 1:100
%         prt('valT = ', toc(tTest));
        displayImage;
%         prt('displayImage = ', toc(tTest));
        set(sH.sliderT, 'Value', valT * sH.sliderTStep);
%         prt('sliderT = ', toc(tTest));
        drawnow nocallbacks;                              % R2014b or later
%         drawnow expose;                                     % R2014a or earlier
%         prt('drawnow = ', toc(tTest));tTest = tic;
    end
    toc

    profile viewer
    profile off
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Nested Subfunctions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function parsePath(filePath)
        
        % Get folder path and set it as shared variable
        [pathFolder, ~, ~] = fileparts(filePath);
        
        if flgGUI
            % Change the filter title accordingly
            set(sH.fig, 'Name', [nameFunction, ' v.', num2str(ver), ' ', pathFolder]);
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function openFile(~,~)
        
        if exist('ND', 'var')
            clear ND;
        end
        
        isDispayReady = false;
        
        % Prompt the user to choose a file
        [fileName, pathFolder, x] = uigetfile({'*.ice', 'ICE Files (*.ice)'; '*.*', 'All Files'}, 'Select ICE file');
        
        path = [pathFolder, fileName];

        % If no file selected
        if x == 0
            return;
        end
        
        parsePath(path);
        initialize(path);
        loadLabels;               
        initializeOverlays;
        isDispayReady = true;
        displayImage
        sH.jFig.getAxisComponent.requestFocus;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function closeAllFiles
        
        % Close all open files
        if exist('fid', 'var') % Is there unclosed fid's?
            for ff = 1:numel(fid)
                if any(fid(ff) == fopen('all')) % Is it a valid file handle?
                    fclose(fid(ff));
                end
            end
            clear fid;
        end
        if exist('fidMIP', 'var') % Is there unclosed fidMIP's?
            for fm = 1:numel(fidMIP)
                if any(fidMIP(fm) == fopen('all')) % Is it a valid file handle?
                    fclose(fidMIP(fm));
                end
            end
            clear fid;
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function quitFile(~,~)
        
        if flgDataModified
            choice = questdlg('Do you want to save the changes to the labels?', 'Overwrite Confirmation', 'Yes', 'No', 'Yes');
            switch choice
                case 'Yes'
                    saveLabels;
            end
        end

        closeAllFiles;
        free(sH.figTS);
        free(sHCtrl.figCtrl);
        free(sH.fig);
        free(hFigBeh);
        
%         if isjava(jF)
%             jF.hide;
%         end

        if issafe('timerObj') && isvalid(timerObj)
            stop(timerObj);
        end
        free(timerObj);
        timerfind('Tag', 'mouseTimer'); % Delete any existing timer
        
        clear all;
        
%         % Clear workspace (not doing this causes memory leak on Jimmy's
%         % computer for some reason related to java slider)
%         vars = who;
%         for i = 1:numel(vars)
%            evalc([vars{i}, '= []']);
%         end
%         return;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function initialize(filePath)

        closeAllFiles;

        % Get file paths
        [path, file, ext] = fileparts(filePath);
        
        file(5) = '1';
        pathICE{1} = [path, '\', file, ext];
        nameFile{1} = file;
        file(5) = '2';
        pathICE{2} = [path, '\', file, ext];
        nameFile{2} = file;
        file(5) = '3';
        pathICE{3} = [path, '\', file, ext];
        
        % Determine how many channels there are
        if exist(pathICE{3}, 'file')
            numCh = 3;
            numChDisp = 2;
            modeIR = 1;
        elseif exist(pathICE{2}, 'file')
            numCh = 2;
            numChDisp = 2;
            modeIR = 0;
        else
            numCh = 1;
            numChDisp = 1;
            modeIR = 0;
        end
        
        if strcmp(file(6:7), 'MX')
            flgMX = true; % If the opened file is an MX file (for MIP)
        else
            flgMX = false;
        end
        
        for p = 1:numCh
            pathICEMX{p} = pathICE{p}; 
            pathICEMX{p}(end-17:end-16) = 'MX';
        end
        
        if exist(pathICEMX{1}, 'file') && ~flgMX &&... % If there is MX file but not opened directly
                ~strcmp(command, 'track')
            flgMIP = true;
        end
   
        varName = ['\Variables_', file(end-10:end), '.mat'];
        
        % Dimension calculations changed to ICE header, 130827 by Ippei
        Str = readHeaderICE(pathICE{1});
        dimT = Str.dimT;
        dimZ = Str.dimZ / Str.stepZ;
        dimY = Str.dimY;
        dimX = Str.dimX;   
        valT = 1;
        valZ = 1;
        
        % Initial image dimentions
        if dimY == 2560
            dimDispY = 2048;
            dimDispX = 2048;
        else
            dimDispY = dimY;
            dimDispX = dimX;
        end
        
        img = zeros(dimDispY, dimDispX, 3, 'uint8');

        sG.sizeROI = 75;
        sG.typeROI = 'ellipse';
        sG.selectZsToMeasure = 'current';
        
        sG.check3D = false;
        sG.showOverlays = true;
        
        % Copy all the files to RAM
        if strcmp(sG.modeImage, 'RAM') || strcmp(modeImageTrack, 'RAM')
            loadImagesToRAM;
        end
        
        % Create memory mapped file
        if strcmp(sG.modeImage, 'map') || strcmp(modeImageTrack, 'map')
            
            s = readHeaderICE(pathICE{1});
            
            imgMap{1} = memmapfile(pathICE{1}, 'Format', {'uint16', [s.dimX s.dimY s.dimT], 'img'}, 'Offset', 4096);
            if numCh >= 2
                imgMap{2} = memmapfile(pathICE{2}, 'Format', {'uint16', [s.dimX s.dimY s.dimT], 'img'}, 'Offset', 4096);
            end
            if numCh == 3
                s3 = readHeaderICE(pathICE{3});
                imgMap{3} = memmapfile(pathICE{3}, 'Format', {'uint16', [s3.dimX s3.dimY s3.dimT], 'img'}, 'Offset', 4096);
            end
        end
        
        % Get variables        
        pathVar = [path, varName];
        sVar = load(pathVar);
        infoND = sVar.infoND;
        ND = rearrangeInfoND(infoND, 2, 5, flgMX);
%         if flgMIP
%             NDMIP = rearrangeInfoND(infoND, 2, 5, true);
%         end
        
        % Determine the name of acquisition program
        if isfield(sVar, 'status')
            str = sVar.status.stack(2).name;
            idx = strfind(str, '/'); % Stack name should be something like 'acquireICE/main'
            if ~isempty(idx)
                modeICE = str(1:idx-1);
            else
                modeICE = str;
            end
        else
            if dimX > 512
                modeICE = 'behaviorICE';
            else
                modeICE = 'acquireICE';
            end
        end
        switch modeICE
            case 'behaviorICE'
                isbehavior = true;
            otherwise
                isbehavior = false;
        end
        
        if isfield(sVar, 'infoND') &&...
                isfield(sVar, 'flgBurstBCECF') &&...
                sVar.flgBurstBCECF % recreate missing ND data for burst BCECF
%             dimND = size(ND{1}, 1);
            ND{2} = ND{1};
            ND{2}(:, 2) = 2; % FrameZ = 2
            ND{2}(:, 5) = 4; % Cube#
%             fr = [ND{1}(1, 1); ones(dimND - 2, 1);ND{1}(end, 1)];
%             tm = [ND{1}(1, 4); ND{2}(2:end - 1, 4);ND{1}(end, 4)];
%             ND{1} = fr;
%             ND{1}(:, 4) = tm;
%             ND{1}(:, 5) = repmat(4, dimND, 1);
        end
        
%         if isfield(sVar, 'flgIntervalBCECF') && sVar.flgIntervalBCECF
%             dimT = size(sVar.infoND, 1);
%         end
        
        dimTP = size(ND{1}, 1); % number of time points considering dimT, dimZ, and # of cubes
        if dimTP * dimZ > dimT
            msg.warning = evalc( 'warning([''There is a discrepancy between file header and ND size.'', char(10), ''dimTP * dimZ > dimT'']);' );
            display(msg.warning);
            dimTP = dimT / dimZ;
        end
        dimC = size(ND, 2); % number of cubes
        
        % Get the first images and min and max pixel values
        img16 = zeros(dimDispY, dimDispX, 3, 'uint16');
        for ch = 1:numCh
            fid(ch) = fopen(pathICE{ch}, 'r');
            stack = loadICE(1, 1, fid(ch), dimX, dimY);
            img16(:, :, ch) = stack(:, :, 1);
            maxIntens(ch) = max(img16(:));            
            img(:, :, ch) = scaleImage(img16(:, :, ch), RGB(1, 1), RGB(1, 2));
        end
        if flgMIP
            for ch = 1:numCh
                fidMIP(ch) = fopen(pathICEMX{ch}, 'r');
%                 img16 = loadICE(1, 1, fidMIP(ch), dimX, dimY);
%                 maxIntens(ch) = max(img16(:));
%                 img(:, :, ch) = scaleImage(img16, RGB(1, 1), RGB(1, 2));
            end
        end
        
        filters = calculateGlobalFilters(stack);

        % Preallocate
        neurons = cell(1,dimZ);
        listNeurons = cell(1,dimZ);
        [listNeurons{1, 1:dimZ}] = deal({}); % Added 140116
%         z_list = 1:dimZ;                % Added 140116
        
%         if numCh >= 2
%             GVF_dx = cell(1,dimZ);
%             GVF_dy = cell(1,dimZ);
%             [GVF_dx{1, 1:dimZ}] = deal(zeros(dimY, dimX, dimTP));
%             [GVF_dy{1, 1:dimZ}] = deal(zeros(dimY, dimX, dimTP));
%         end
        
        if flgGUI
            clearHandles; % Clear leftover handles
            
            
%             jimg = im2java(img16);
%             if isjava(jF)
%                 jF.hide;
%             end
%             jF = javax.swing.JFrame;
%             jF.setUndecorated(true);
%             icon = javax.swing.ImageIcon(jimg);
%             jLabel = javax.swing.JLabel(icon);
%             jF.getContentPane.add(jLabel);
%             jF.pack;
%             screenSize = get(0,'ScreenSize');  %# Get the screen size from the root object
%             screenSize(3) = 1200;
%             screenSize(4) = 1920;
%             jF.setSize(screenSize(3),screenSize(4));
%             jF.setLocation(0,0);
%             jF.show;

%             img = uint8(img ./ (maxIntens(1) / 2^8)); % Convert it to 8 bit interger for speed

            if isbehavior
                img = img(1:2:end, 1:2:end, 1);
            end
            hImage = image(img, 'Parent', sH.axisImage); % Image handle
            rangeDefaultX = xlim(sH.axisImage);
            rangeDefaultY = ylim(sH.axisImage);
            set(hImage, 'ButtonDownFcn', @ImageClick);
            colormap(gray(256));

            set(sH.axisImage, 'xtick', [], 'ytick', []);
            
            if dimY >= 2048
                selectMenu([], [], '&Layers', '&Red'); % Default image mode
            else
                selectMenu([], [], '&Layers', 'RG&B'); % Default image mode
            end            
   
            sH = createSliders(sH, hFunctions, dimTP, dimZ, RGB, smallScreen, depthColor);
%             set(sH.SelectZ, 'Enable', 'on');
%             set(sH.SelectZ, 'String', z_list);
%             enableOptions;      % Enable option buttons

        end

        if flgGUI && ~sG.dragzoom
            dragzoomMod(sH.axisImage, [], hFunctions);
            sG.dragzoom = true;
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Main function for the display
    function displayImage(currentT)
      
        % If there's an input argument, then use it as a current time point
        if nargin == 1
            valT = currentT;
        end
        
        if isDispayReady
            tDisp = tic;
            
            % Get the current frame; make sure frame number stays within the range
            if(valT > dimTP)
                valT = dimTP;
            elseif(valT <  1)
                valT = 1;
            end
            if(valZ > dimZ)
                valZ = dimZ;
            elseif(valZ <  1)
                valZ = 1;
            end
            fr = getCurrentFrameFromND(valZ, valT);
%             img = zeros(dimDispY, dimDispX, 3, 'uint8');

            switch sG.layers
                case 'red'
                    switch sG.modeImage
                        case 'RAM'
                            img16(:, :, 1) = imgRAM{1}(:, :, fr(1));
                        case 'map'
                            img16(:, :, 1) = imgMap{1}.Data.img(:, :, fr(1));
                        otherwise
                            img16(:, :, 1) = loadICE(fr(1), 1, fid(1), dimX, dimY);
                    end

                    if sG.applyFilter
                        img16(:, :, 1) = filterImage(img16(:, :, 1), filters);
                    end
%                     tic
                    img = scaleImage(img16(:, :, 1), RGB(1, 1), RGB(1, 2));
%                     colormap(vivid(RGB(1,:)));
                case 'green'
                    if numCh >= 2
                        switch sG.modeImage
                            case 'RAM'
                                img16(:, :, 2) = imgRAM{2}(:, :, fr(2));
                            case 'map'
                                img16(:, :, 2) = imgMap{2}.Data.img(:, :, fr(2));
                            otherwise
                                img16(:, :, 2) = loadICE(fr(2), 1, fid(2), dimX, dimY);
                        end
                        img = scaleImage(img16(:, :, 2), RGB(2, 1), RGB(2, 2));
%                         colormap(vivid(RGB(2,:)));
                        %                 prt( mean(img16(:)), RGB(2, 1), RGB(2, 2) );
                    end
                case 'RGB'
                    if numCh >= 2
%                         img16 = zeros(dimDispY, dimDispX, 3, 'uint16');
                        for ch = 1:numChDisp
                            switch sG.modeImage
                                case 'RAM'
                                    img16(:, :, ch) = imgRAM{ch}(:, :, fr(ch));
                                case 'map'
                                    img16(:, :, ch) = imgMap{ch}.Data.img(:, :, fr(ch));
                                otherwise
                                    img16(:, :, ch) = loadICE(fr(ch), 1, fid(ch), dimX, dimY);
                            end
                            img(:, :, ch) = scaleImage(img16(:, :, ch), RGB(ch, 1), RGB(ch, 2));
%                             colormap(vivid(RGB));
                        end
                        % For IR images
                        if modeIR && (1 >= valT)
                            img16(:, :, 3) = loadICE(fr(1), 1, fid(3), dimX, dimY);
                            img(:, :, 3) = scaleImage(img16(:, :, 3), RGB(3, 1), RGB(3, 2));
                        else
                            img(:, :, 3) = zeros(dimDispX, dimDispY, 'uint8');
                        end
                    end
                case 'max'
                
                    if numCh >= 2
                        if flgMIP
                            for ch = 1:numChDisp
                                switch sG.modeImage
                                    case 'RAM'
                                        img16(:, :, ch) = imgRAMMIP{ch}(:, :, valT);
%                                         img(:, :, ch) = scaleImage( img16, RGB(ch, 1), RGB(ch, 2) );
                                    case 'map'
                                        img16(:, :, ch) = imgMapMIP{ch}.Data.img(:, :, valT);
%                                         img(:, :, ch) = scaleImage( img16, RGB(ch, 1), RGB(ch, 2) );
                                    otherwise
                                        img16(:, :, ch) = loadICE(valT, 1, fidMIP(ch), dimX, dimY);
                                end
                                img(:, :, ch) = scaleImage( img16(:, :, ch), RGB(ch, 1), RGB(ch, 2) );
                            end
                        else
                            % Vectorized way to get certain range of variables from a cell by anonymous function
                            all_planes = cellfun(@(x) x(valT, 1), ND);
                            planeMin = min(all_planes);
                            
                            for ch = 1:numChDisp
                                switch sG.modeImage
                                    case 'RAM'
                                        img16(:, :, ch) = max(imgRAM{ch}(:, :, planeMin:planeMin + dimZ - 1), [], 3);
                                    case 'map'
                                        img16(:, :, ch) = max(imgMap{ch}.Data.img(:, :, planeMin:planeMin + dimZ - 1), [], 3);
                                    otherwise
                                        img16(:, :, ch) = max(loadICE(planeMin, dimZ, fid(ch), dimX, dimY), [], 3);
                                end
                                img(:, :, ch) = scaleImage( img16(:, :, ch), RGB(ch, 1), RGB(ch, 2) );
                            end
                        end
                        
                        % For IR images
                        if modeIR && (1 >= valT)
                            imgIR(:, :, :) = loadICE(1, dimZ, fid(3), dimX, dimY);
                            img16(:, :, 3) = squeeze(max(imgIR, [], 3));
                            img(:, :, 3) = scaleImage(img16(:, :, 3), RGB(3, 1), RGB(3, 2));
                        else
                            img(:, :, 3) = zeros(dimDispX, dimDispY, 'uint8');
                        end
                    end
            end

            if isbehavior
                img = img(1:2:end, 1:2:end);
            end
            % Checks for image flipping; Added 140130
            if sG.flipVertical
                img = flip(img, 1);
            end
            if sG.flipHorizontal
                img = flip(img, 2);
            end
            
            if ~exist('img', 'var')
                img = nan(dimX, dimY);
            end

            set(hImage, 'CData', img);
%             hImage.CData = img;

%             jimg = im2java(img);
%             icon = javax.swing.ImageIcon(jimg);
%             jLabel.setIcon(icon);

%---------------------------------------------------------------------------------------------------------------------------------
            % Draw overlays
            if ~sG.showOverlays, eDisp = toc(tDisp); return, end

            % Size adjustments of overlays for different window sizes
            if smallScreen
                fs = 7;
                ms = 2;
                sn = 6;
            else
                fs = 9;
                ms = 3;
                sn = 9;
            end
         
            % Get labels
%             labels = []; nrnsMip = [];
            
%             labels = nameNeurons{:};

            switch sG.layers
                case 'max'
%                     nr = []; nc = [];
%                     for z = 1:dimZ
%                         for n = 1:numel(neurons{z}(:))
%                             if ~strcmp(neurons{z}{n}.name(1:3),'neu') 
%                                 labels = [labels; {neurons{z}{n}.name}];
%                                 nr = [nr; neurons{z}{n}.pos(valT, 1)];
%                                 nc = [nc; neurons{z}{n}.pos(valT, 2)];
%                                 dimN = dimN + 1;
%                             end
%                         end
%                     end

                    dimN = getLabelsMip;
%                     updateList;

                    sG.modeMip = true;
                otherwise
                    sG.modeMip = false;
                    switch modeICE
                        case 'acquireICE'
                            %labels = neurons{valZ};
%                             labels = nameNeurons{:};
%                             if ~isempty(labels)
%                                 labels = strrep(labels, 'ON', '^{ON}');
%                                 labels = strrep(labels, 'OFF', '^{OFF}');
%                             end
                            nameNeurons = readNeurons(neurons(valZ), 'name');
                            labels = nameNeurons{:};
                            dimN = numel(nameNeurons{:});    % Number of neurons in this z-level
                            nr = zeros(dimN, 1);
                            nc = zeros(dimN, 1);
                            
                            for n = 1:dimN
                                nr(n, 1) = neurons{valZ}{n}.pos(valT, 1);
                                nc(n, 1) = neurons{valZ}{n}.pos(valT, 2);
                            end
                        case 'behaviorICE'
                            if isempty(worms) || ~isfield(worms, 'wormNumber')
                                eDisp = toc(tDisp);
                                return
                            end
                            nc = cat(1, worms.coordinatesX);
                            nr = cat(1, worms.coordinatesY);
                            dimN = numel(worms);
                            labels = arrayfun(@(x) num2str(x), [worms.wormNumber]' ,'UniformOutput', false);
                    end
            end
            if ~isempty(labels)
                labels = strrep(labels, 'ON', '^{ON}');
                labels = strrep(labels, 'OFF', '^{OFF}');
            end
            
            %             % Get positions
%             switch modeICE
%                 case 'acquireICE'
% %                     dimN = numel(nameNeurons{:});    % Number of neurons in this z-level
% %                     nr = zeros(dimN, 1);
% %                     nc = zeros(dimN, 1);
% % 
% %                     for n = 1:dimN
% %                         nr(n, 1) = neurons{valZ}{n}.pos(valT, 1);
% %                         nc(n, 1) = neurons{valZ}{n}.pos(valT, 2);
% %                     end
%                 case 'behaviorICE'
% %                     nc = cat(1, worms.coordinatesX);
% %                     nr = cat(1, worms.coordinatesY);
% %                     dimN = numel(worms);
%             end

            % Checks for image flipping
            if sG.flipVertical
                nr = dimDispY - nr;
            end
            if sG.flipHorizontal
                nc = dimDispX - nc;
            end

            % Plot selected point
            if dimN
                nSlctd = get(sH.listN,'Value'); % Get selected neuron
                if ~isempty(nc)
                    if issafe('hSelPoint')
                        set(hSelPoint, 'xdata', nc(nSlctd), 'ydata', nr(nSlctd));
                        set(hSelPoint, 'MarkerSize', sn);
                        set(hSelPoint, 'Visible', 'on');
                    end
                end
            elseif issafe('hSelPoint')
                set(hSelPoint, 'Visible', 'off');
            end
            
            % Plot all other points
            if (~isempty(nc) && any(nc ~= 0) && ~isempty(hPoints))
                set(hPoints, 'xdata', nc, 'ydata', nr);
                set(hPoints, 'MarkerSize', ms);
                set(hPoints, 'Visible', 'on');
            elseif issafe('hPoints')
                set(hPoints, 'Visible', 'off');
            else
                % Plot neuron points
                if any(nr ~= 0) && any(nc ~= 0)
                    hPoints = line(nc, nr, 'Marker', 'o', 'MarkerEdgeColor', colorPointsEdge,...
                        'MarkerFaceColor', colorPointsFace, 'LineStyle', 'none', ...
                        'Parent', sH.axisImage, 'Visible', 'off');
                    set(hPoints, 'ButtonDownFcn', @ImageClick);
                end
            end
            
            % Plot the labels
            if sG.showLabels && ~isempty(labels) && ~isempty(nr) && exist('hLabels', 'var');
                % Delete cell labels if the current ones are different from the previous ones
                if numel(hLabels) ~= numel(nc) || size(labelsPrev , 1) ~= size(labels, 1) || any( ~strcmp(labelsPrev, labels) )
                    
                    arrayfun(@(h) free(h, false), hLabels);
                    clear hLabels;
                    hLabels = text(nc+3 ,nr, arrayfun(@(x) strrep(x, 'neuron', ''), labels(:) ),...
                        'color', 'white', 'Parent', sH.axisImage, 'FontSize', fs);
                    set(hLabels, 'ButtonDownFcn', @ImageClick);
                else
                    arrayfun(@(h, c, r) set(h, 'Position', [c, r]), hLabels, nc+3, nr);
                end
                
                labelsPrev = labels;
            end
        
            % Draw the mask boundary
            if sG.showRegions && exist('nSlctd', 'var')
                nrn = neurons{valZ}{nSlctd};
                dim = size(nrn.segm_crop_pos,2) / 2; % Dimension
                if dim == 2 % 2D-tracked neuron
                    mask_bdry = bwboundaries(nrn.segm(:,:,valT)); % Segmentation boundary
                    % Adjust for cropped image
                    if ~isempty(nrn.segm_crop_pos)
                        mask_bdry{1}(:, 1) = mask_bdry{1}(:, 1) + nrn.segm_crop_pos(valT, 1) - 1;
                        mask_bdry{1}(:, 2) = mask_bdry{1}(:, 2) + nrn.segm_crop_pos(valT ,3) - 1;
                    end
                    
                    % Filp the boundary
                    if sG.flipVertical
                        mask_bdry{1}(:, 1) = dimDispY - mask_bdry{1}(:, 1);
                    end
                    if sG.flipHorizontal
                        mask_bdry{1}(:, 2) = dimDispX - mask_bdry{1}(:, 2);
                    end
                    
                    if ~isempty(mask_bdry)  % If a valid segmentation
                        set(hMask, 'xdata', mask_bdry{1}(:,2), 'ydata', mask_bdry{1}(:,1));
                        set(hMask, 'Visible', 'on');
                    elseif exist('hMask', 'var') && ishandle(hMask)
                        set(hMask, 'Visible', 'off');
                    end
                elseif dim == 3 % 3D-tracked neuron
                    neuron = labels{nSlctd};
                    z_min = neuron.segm_crop_pos(valT,5);
                    z_max = neuron.segm_crop_pos(valT,6);
                    
                    if (z_min <= valZ) && (valZ <= z_max)
                        z_actual = 1 + valZ - z_min;
                        mask_bdry = bwboundaries(neuron.segm(:,:,z_actual,valT));   % Segmentation bdry
                        % Adjust for cropped image
                        if ~isempty(neuron.segm_crop_pos)
                            mask_bdry{1}(:,1) = mask_bdry{1}(:,1) + neuron.segm_crop_pos(valT,1) - 1;
                            mask_bdry{1}(:,2) = mask_bdry{1}(:,2) + neuron.segm_crop_pos(valT,3) - 1;
                        end
                        if ~isempty(mask_bdry)
                            set(hMask, 'xdata', mask_bdry{1}(:,2), 'ydata', mask_bdry{1}(:,1));
                            if showOverlays
                                set(hMask, 'Visible', 'on');
                            end
                        elseif issafe('hMask')
                            set(hMask, 'Visible', 'off');
                        end
                    elseif issafe('hMask')
                        set(hMask, 'Visible', 'off');
                    end
                elseif issafe('hMask')
                    set(hMask, 'Visible', 'off');
                end
            elseif issafe('hMask')
                set(hMask, 'Visible', 'off');
            end

            % Gradient vector field
            if sG.showGVF
                w = fspecial('disk',3); % Smoothing filter
                dx = imfilter(GVF_dx{valZ}(:,:,valT), w, 'replicate');
                dy = imfilter(GVF_dy{valZ}(:,:,valT), w, 'replicate');
                [x, y] = meshgrid(1:dimX, 1:dimY);
                hold on
                hQuiver = quiver(x, y, dx, dy, 'Parent', sH.axisImage);
                hold off
                set(hQuiver, 'ButtonDownFcn', @ImageClick);
            end
            eDisp = toc(tDisp);
        end

    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function runOptionCommand
        if ~exist('flgWI', 'var')
            flgWI = false;
        end
        if ~exist('handlesWI', 'var')
            handlesWI = nan;
        end
        if ~exist('tWI', 'var')
            tWI = nan;
        end
        
        if exist('command', 'var')
            
            switch command
                case 'track'
                    parsePath(arginPath);
                    sG.modeImage = 'RAM';
                    
                    initialize(arginPath);
                    
                    if flgWI
                        updateElapsedTime(handlesWI, tWI);
                        set(handlesWI.textProcess,'String', 'Seed Calculation');
                        drawnow;
                    end
                    
                    getSeedsGateway;
                    
                    if flgWI
                        updateElapsedTime(handlesWI, tWI);
                        set(handlesWI.textProcess,'String', 'Tracking');
                        drawnow;
                    end
                    
                    trackAllGateway;
                    
                    save([pathFolder, '\', 'neurons.mat'], 'neurons');
                    
                    closeAllFiles;
            end
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function fr = getCurrentFrameFromND(currentZ, cuurentT)
        
        if ~exist('ND', 'var')
            fr = 1;
            return
        end
        
        if dimC == 1
            fr(1:2) = ND{currentZ}(cuurentT, 1);
        elseif dimC == 2
            
            for cc = 1:2
                fr(cc) = ND{currentZ, cc}(cuurentT, 1); %#ok<AGROW> % for multi-cube images (BCECF)
            end
            
        end
        if any(fr > dimT)
            fr(fr>dimT) = dimT;
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function initializeOverlays(argNeurons)
        
        if exist('argNeurons', 'var')
            neurons = argNeurons;
        end
        
        switch modeICE
            case 'acquireICE'
                if isempty(neurons{valZ})
                    return
                elseif strcmp(sG.layers, 'max')
                    dimN = getLabelsMip;
                    updateList;
                    dimI = dimN;
                else
                    dimI = numel(neurons{valZ});
                    nr = zeros(dimI, 1);
                    nc = zeros(dimI, 1);
                    for n = 1:dimI
                        nr(n, 1) = neurons{valZ}{n}.pos(valT, 1);
                        nc(n, 1) = neurons{valZ}{n}.pos(valT, 2);
                    end
                end
            case 'behaviorICE'
                if isempty(worms)
                    return
                else
                    dimI = size(worms, 2);
                    nc = cat(1, worms.coordinatesX);
                    nr = cat(1, worms.coordinatesY);                    
                end
        end

        clearHandles

        z = valZ;

        if dimI
            % Get selected neuron
            nSlctd = get(sH.listN, 'Value');
            if nSlctd > dimI
                prt('Selected item is larger (', nSlctd, ') than the list (', dimI, ').');
                return
            end
            
            if 1
                % Plot the point in green
                hSelPoint = line(nc(nSlctd) ,nr(nSlctd), 'Marker', 'o', 'MarkerEdgeColor', colorSelectedPointEdge,...
                    'MarkerFaceColor', colorSelectedPointFace, 'LineStyle', 'none', 'Parent', sH.axisImage,...
                    'Visible', 'off');
                set(hSelPoint, 'ButtonDownFcn', @ImageClick);
                if sG.showOverlays
                    set(hSelPoint, 'Visible', 'on');
                end
            end
        end

        % Draw the mask boundary if that option is selected
        if strcmp(modeICE, 'acquireICE') && sG.showRegions && exist('nSlctd', 'var')
            dim = size(neurons{z}{nSlctd}.segm_crop_pos,2) / 2; % Dimension
            
            if dim == 2 % 2D-tracked neuron
                bm = bwboundaries(neurons{z}{nSlctd}.segm(:,:,valT)); % Segmentation boundary
                % Adjust for cropped image
                if ~isempty(neurons{z}{nSlctd}.segm_crop_pos)
                    bm{1}(:, 1) =...
                        bm{1}(:, 1) + neurons{z}{nSlctd}.segm_crop_pos(valT, 1) - 1;
                    bm{1}(:, 2) =...
                        bm{1}(:, 2) + neurons{z}{nSlctd}.segm_crop_pos(valT ,3) - 1;
                end
                if ~isempty(bm)                              % If a valid segmentation
                    hMask = line(bm{1}(:,2), bm{1}(:, 1), 'Color', 'r', 'Parent', sH.axisImage, 'LineWidth', 1);
                    set(hMask, 'ButtonDownFcn', @ImageClick);
                end
            elseif dim == 3 % 3D-tracked neuron
                neuron = neurons{z}{nSlctd};
                z_min = neuron.segm_crop_pos(valT,5);
                z_max = neuron.segm_crop_pos(valT,6);
                
                if (z_min <= valZ) && (valZ <= z_max)
                    z_actual = 1 + valZ - z_min;
                    bm = bwboundaries(neuron.segm(:,:,z_actual,valT));   % Segmentation bdry
                    % Adjust for cropped image
                    if ~isempty(neuron.segm_crop_pos)
                        bm{1}(:,1) = bm{1}(:,1) + neuron.segm_crop_pos(valT,1) - 1;
                        bm{1}(:,2) = bm{1}(:,2) + neuron.segm_crop_pos(valT,3) - 1;
                    end
                    if ~isempty(bm)
                        hMask = line(bm{1}(:,2), bm{1}(:,1), 'Color', 'r', 'Parent', sH.axisImage, 'LineWidth', 1);
                        set(hMask, 'ButtonDownFcn', @ImageClick);
                    end
                end
            end
        end
        
        % Plot neuron points
        if any(nr ~= 0) && any(nc ~= 0)
            hPoints = line(nc, nr, 'Marker', 'o', 'MarkerEdgeColor', colorPointsEdge,...
                'MarkerFaceColor', colorPointsFace, 'LineStyle', 'none', ...
                'Parent', sH.axisImage, 'Visible', 'off');
            set(hPoints, 'ButtonDownFcn', @ImageClick);
            if sG.showOverlays
                set(hPoints, 'Visible', 'on');
            end
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Clear handles of various graphic objects
    function clearHandles
        % Selected point

        free(hSelPoint);
        hSelPoint = [];

        
        % Delete plotted points
%         if issafe('hPoints')
            free(hPoints);
            hPoints = [];
%         end
        
        % Delete cell labels
        if issafe('hLabels')
            free(hLabels);
            hLabels = [];
        end

        % Mask boundary
%         if issafe('hMask')
            free(hMask);
            hMask = [];
%         end

        % GVF
%         if issafe('hQuiver')
            free(hQuiver);
            hQuiver = [];
%         end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function loadImagesToRAM
        numChunks = 50;  % number of steps/chunks
        for ld = 1:numChDisp
            progressBar(flgGUI, sH, 'initiate', ['Loading ', nameFile{ld}, ' to RAM ...']);
            s = readHeaderICE(pathICE{ld});
            lenData = s.dimT;
            % Load ICE file to RAM in chunks
            indData = [1 : round(lenData/numChunks) : lenData, lenData+1];
            numChunks = numel(indData); % # of chunks may be different from original numChunks
            fd = fopen(pathICE{ld}, 'r');
            imgRAM{ld} = zeros(dimDispY, dimDispX, lenData, 'uint16');
            lf = 0;
            for indChunk = 0 : numChunks - 2
                imgRAM{ld}(:, :, indData(indChunk+1):indData(indChunk+2)-1) = loadICE(indData(indChunk+1),...  % first frame
                    (indData(indChunk+2)-1 - indData(indChunk+1) + 1), fd, dimX, dimY); % # of frames to load 
                progressBar(flgGUI, sH, 'iterate', [], indChunk, (numChunks-2));
                lf = prtprg(indChunk, (numChunks-2), lf, 'Loading file:');
            end
            fclose(fd);
            progressBar(flgGUI, sH, 'terminate', 'Finished loading.');
        end
        
        % Load IR image to RAM
        if numCh == 3
            fd = fopen(pathICE{3}, 'r');
            s = readHeaderICE(pathICE{3});
            imgRAM{3} = loadICE(1, s.dimT, fd, dimX, dimY);
            fclose(fd);
        end
        
        % Load MIP files if exist
        if flgMIP
            for ch = 1:2
                fd = fopen(pathICEMX{ch}, 'r');
                imgRAMMIP{ch} = loadICE(1, dimTP, fd, dimX, dimY);
            end
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Scale images
%     function imgOut = scaleImage(imgIn, maxIntensity, minIntensity)
%         imgOut = uint8(((imgIn - minIntensity)) / (uint16(maxIntensity) / 2^8));
%     end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function scrollSliderT(~, ~)
        
        % Dynamically adjust diplay timing according to display time of the last frame
%         weightDisplay = eDisp * 1;
        
%         if toc(tScroll) > weightDisplay
        if true
            val = get(sH.sliderT, 'Value');   % Get the time index
%             prt('sliderT = ', toc(tTest));
            valT = round(val * (dimTP-1) + 1);
%             prt(valT);
            % Update to the selected image
%             prt('valT = ', toc(tTest));
            displayImage;
%             prt('displayImage = ', toc(tTest));
            updateDisplayStatus
%             prt('updateDisplayStatus = ', toc(tTest));
            drawVline;
%             prt('drawVline = ', toc(tTest));tTest = tic;
%             tScroll = tic;  % Reset scroll timer
        end
%         sH.jFig.getAxisComponent.requestFocus;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function resetTime
        valT = 1;
        set(sH.sliderT, 'Value', valT);
        displayImage;
        updateDisplayStatus
        drawVline
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function drawVline
        if issafe('sH.figTS')
            % Delete previous vline
%             if ishandle(hVL)
                free(hVL);
%             end
%             if ishandle(hVLT)
                free(hVLT);
%             end

            switch sG.layers
                case 'max'
                    z = 1;
                otherwise
                    z = valZ;
            end

            % Draw vline on scrollable plot if exists
            sn = get(sH.listN, 'Value');
            if isfield(sH, 'axesPlots') && ~isempty(sH.axesPlots{z}) && ishandle(sH.axesPlots{z}(sn))
                hVL = drawVerticalLine(sH.axesPlots{z}(sn), ND{z}(valT, 4));
            end
            if isfield(sH, 'axisTemp') && ~isempty(sH.axisTemp) && ishandle(sH.axisTemp)
                hVLT = drawVerticalLine(sH.axisTemp, ND{z}(valT, 4));
            end
            
        elseif issafe('hFigBeh')
%             if ishandle(hVLB)
                free(hVLB);
%             end
            if exist('hAxisBeh', 'var') && ~isempty(hAxisBeh) && ishandle(hAxisBeh)
                hVLB = drawVerticalLine(hAxisBeh, valT);
            end
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function scrollByWheel(~, event)
       
        % Dynamically adjust diplay timing according to display time of the last frame
%         weightDisplay = eDisp * 1;

        if sG.safeWheel == false
            return
        end

        % Update images only when it has been long enough since the
        % last update. Updating too often causes jerky animation.
        if (toc(tScroll) > weightDisplay) && ~isscrolling
            isscrolling = true;

            % Get a scroll count of the wheel movement
            val = event.getWheelRotation;
%             prt(val);

            % Change T or Z values according to the mouse wheel movement
            if event.getModifiers == 1 && issafe('sH.jScrollBarZ') % if Shift key is pressed
                valZ = valZ + round(val);
                % Make sure valZ is in the valid range
                if(valZ > dimZ)
                    valZ = dimZ;
                elseif(valZ <  1)
                    valZ = 1;
                end
                set(sH.listN, 'Value', 1); % Reset the list selection
                set(sH.jScrollBarZ, 'Value', valZ);
                updateList;
                initializeOverlays;
                set(sH.listN, 'Value', 1);
            elseif dimTP > 1
                valT = valT + round(val * 1) + scrollAccumulation;
                % Make sure valT is in the valid range
                if(valT > dimTP - 1)
                    valT = dimTP - 1;
                elseif(valT <  1)
                    valT = 1;
                end
%                 set(sH.sliderT, 'Value', valT);
                set(sH.sliderT, 'Value', valT * sH.sliderTStep);
            end

            displayImage;
            updateDisplayStatus
            drawVline
            
            sH.jFig.getAxisComponent.requestFocus;
            tScroll = tic;  % Reset scroll timer
            isscrolling = false;
            scrollAccumulation = 0;
        else
            val = event.getWheelRotation;
            if event.getModifiers == 8 % Alt
                val = val * 2;
            elseif event.getModifiers == 9 % Alt + Shift
                val = val * 10;
            end
            scrollAccumulation = scrollAccumulation + val;
        end
        
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Z slider
    function scrollSliderZ(~, ~)
        
        if toc(tScroll) > weightDisplay
            
            set(sH.listN, 'Value', 1); % Reset the list selection
            valZ = round(get(sH.jScrollBarZ, 'Value'));    % Get the z index
            % Update the neuron list
            updateList;
            
            initializeOverlays;
            
            % Update to the selected image
            displayImage;

            %set(handles.listN, 'Value', 1); % Deleted 140116
            tScroll = tic;  % Reset scroll timer
        end
        set(sH.jScrollBarZ, 'Value', valZ);               % 'Snap' the slider
        
        % Change the z-plane of Calcium Dynamics window if it exists
        if ishandle(sH.figTS)
            set(sH.panelNeurons(:), 'Visible', 'off');
            if sG.showOverlays
                set(sH.panelNeurons(valZ), 'Visible', 'on');
            end
            set(sH.figTS, 'Name', ['Calcium Dynamics: Plane = ', num2str(valZ)]);
        end
        updateDisplayStatus
        sH.jFig.getAxisComponent.requestFocus;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function updateDisplayStatus
        if ~isempty(sH.statusBar) && exist('ND', 'var')
            sH.statusBar.setText(...
                sprintf( ['% 7.2f ms (TRD) % 3.0u/%3.0u (T) % 2.0u/%1.0u (Z) % 4.0u/%3.0u (F) ',...
                '% 7.2f sec   Coordinates = [%4.0f, %4.0f]  RGB = [%5.0f, %5.0f, %5.0f]'],...
                eDisp*1000, valT, dimTP, valZ, dimZ, ND{valZ}(valT, 1), dimT, ND{valZ}(valT, 4),...
                posX, posY, intensityR, intensityG, intensityB));
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function movePlot
        
       if ishandle(sH.figTS)
           valL = get(sH.listN, 'Value');
           maxSlider = get(sH.jScrollBarTS, 'maximum');
           minSlider = get(sH.jScrollBarTS, 'minimum');
           numList = numel(get(sH.listN, 'String'));
           sizeKnob = sH.jscrollbar.getVisibleAmount;
           newVal = ((maxSlider - sizeKnob - minSlider) / (numList - 1)) * (valL - 1);
           if isnan(newVal)
               newVal = 1;
           end
           set(sH.jScrollBarTS, 'Value', newVal); 
       end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% RGB slider callback
    function changeMerge(hObj, ~, sliderNum)
        
        val = round(hObj.getValue);
        
        switch sliderNum
            case 1
                RGB(1, 1) = val; % R max
            case 2
                RGB(1, 2) = val; % R min
            case 3
                RGB(2, 1) = val; % G max
            case 4
                RGB(2, 2) = val; % G min
            case 5
                RGB(3, 1) = val; % B max
            case 6
                RGB(3, 2) = val; % B min
        end
        
        if any(RGB(:, 1) <= RGB(:, 2))
            RGB(RGB(:, 1) <= RGB(:, 2), 1) = RGB(RGB(:, 1) <= RGB(:, 2), 2) + 1; % make sure max > min
        end
        
        set(sH.jSliderRGB{sliderNum}, 'ToolTipText', num2str(val));
        
        changeColorMap;
        displayImage;
        sH.jFig.getAxisComponent.requestFocus;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function changeColorMap
        switch sG.layers
            case 'red'
                colormap( vividgray(RGB(1,:)) );
                %                 set(sH.axisImage, 'CLim', [RGB(1, 2), RGB(1, 1)]);
            case 'green'
                colormap( vividgray(RGB(2,:)) );
                %                 set(sH.axisImage, 'CLim', [RGB(1, 2), RGB(1, 1)]);
            otherwise
                %                 colormap(sH.axisImage, vivid(RGB));
                colormap(gray(256));
                %                 set(sH.axisImage, 'CLim', [RGB(1, 2), RGB(1, 1)]);
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function autoscaleRGB(~, ~)
        
        frmCur = ND{valZ}(valT, 1);
        
        im = zeros(dimDispY, dimDispX, 3, 'uint16');
        
        for ch = 1:numCh
            if flgMIP && strcmp(sG.layers, 'max')
                im(:, :, ch) = loadICE(valT, 1, fidMIP(ch), dimX, dimY);
                
%                 RGB(ch, 1) = max(reshape(img16(:, :, ch), 1, dimDispY * dimDispX)) + 10;
%                 RGB(ch, 2) = min(reshape(img16(:, :, ch), 1, dimDispY * dimDispX));
            else
                im(:, :, ch) = loadICE(frmCur, 1, fid(ch), dimX, dimY);

%                 RGB(ch, 1) = max(reshape(img16(:, :, ch), 1, dimDispY * dimDispX)) + 10;
%                 RGB(ch, 2) = min(reshape(img16(:, :, ch), 1, dimDispY * dimDispX));
            end
            switch modeICE
                case 'acquireICE'
                    RGB(ch, :) = strechHist(im(:,:,ch), 0.1, 0.9999, 2^16);
                case 'behaviorICE'
                    RGB(ch, :) = strechHist(im(:,:,ch), 0.1, 0.999, 2^8);

            end
            changeDepthControls(ch);
        end
        disp(RGB);
%         imgD = double(img16);
%         imgD(imgD == 0) = [];
%         lh = stretchlim(imgD(imgD(:,:,1) ~= 0), [0.00001 0.999999]);
        
%         RGB = circshift(lh', 1, 2) * (2^16-1)
        
        changeColorMap;
        displayImage;
        sH.jFig.getAxisComponent.requestFocus;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function changeDepthControls(channel)
        
        % Change depth menu
        switch channel
            case 1
                set(sH.menuDepthColorR, 'Value', findDepthMenuValue(RGB(channel, 1)));
            case 2
                set(sH.menuDepthColorG, 'Value', findDepthMenuValue(RGB(channel, 1)));
            case 3
                set(sH.menuDepthColorB, 'Value', findDepthMenuValue(RGB(channel, 1)));
        end
        
        % Store depth value
        depthColor(channel, 1) = findDepthColor( RGB(channel, 1) );
        set(sH.jSliderRGB{channel*2-1}, 'maximum', 2^depthColor(channel, 1) );
        depthColor(channel, 2) = findDepthColor( RGB(channel, 2) );
        set(sH.jSliderRGB{channel*2}, 'maximum', 2^depthColor(channel, 2) );
        
        % Change RGB sliders
        set(sH.jSliderRGB{channel*2-1}, 'Value', RGB(channel, 1), 'ToolTipText', num2str( RGB(channel, 1) ) );
        set(sH.jSliderRGB{channel*2}, 'Value', RGB(channel, 2), 'ToolTipText', num2str( RGB(channel, 2) ) );
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function value = findDepthMenuValue(intensity)
        value = 1;
        for dc = 14:-2:8
            if intensity >= 2^dc
                break;
            else
                value = value + 1;
            end
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function depth = findDepthColor(intensity)
        for depth = 8:2:16
            if intensity <= 2^depth
                break;
            end
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function changeDepthColor(hObj, ~, channel)
        
        dc = get(hObj, 'Value');
        
        switch dc
            case 1
                depthColor(channel, 1) = 16;
                depthColor(channel, 2) = 14;
            case 2
                depthColor(channel, 1) = 14;
                depthColor(channel, 2) = 12;
            case 3
                depthColor(channel, 1) = 12;
                depthColor(channel, 2) = 10;
            case 4
                depthColor(channel, 1) = 10;
                depthColor(channel, 2) = 8;
            case 5
                depthColor(channel, 1) = 8;
                depthColor(channel, 2) = 6;
        end

        for is = 1:6
            if rem(is, 2) % Odd number index (max RGB sliders)
                set(sH.jSliderRGB{is}, 'maximum', 2^depthColor(channel, 1), 'minimum', 0);
            else
                set(sH.jSliderRGB{is}, 'maximum', 2^depthColor(channel, 2), 'minimum', 0);
            end
        end
        sH.jFig.getAxisComponent.requestFocus;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function toggleRGB(hObj, ~, channel)

        checked = get(hObj, 'Value');
        
        if checked
            switch channel
                case 'R'
                    val = get(sH.jSliderRGB{2}, 'Value');
                    RGB(1, 2) = val; % R min
                case 'G'
                    val = get(sH.jSliderRGB{4}, 'Value');
                    RGB(2, 2) = val; % G min
                case 'B'
                    val = get(sH.jSliderRGB{6}, 'Value');
                    RGB(3, 2) = val; % B min
            end            
        else
            switch channel
                case 'R'
                    RGB(1, 2) = 2^16; % R min
                case 'G'
                    RGB(2, 2) = 2^16; % G min
                case 'B'
                    RGB(3, 2) = 2^16; % B min
            end
        end
        displayImage;
        sH.jFig.getAxisComponent.requestFocus;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Toggle overlay display
    function toggleOverlays
        if issafe('hPoints')
            if sG.showOverlays
                toggleThese('hSelPoint', 'hPoints', 'hLabels', 'off');
                sG.showOverlays = false;
            else
                toggleThese('hSelPoint', 'hPoints', 'hLabels', 'on');
                sG.showOverlays = true;
            end
        end
%-----------------------------------------------------------------------------------------------------------------------       
        function toggleThese(hS, hP, hL, sw)
            if issafe(hS)
                set(eval(hS), 'Visible', sw);
            end
            if issafe(hP)
                set(eval(hP), 'Visible', sw);
            end
            if issafe(hL)
                set(eval(hL), 'Visible', sw);
            end
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Change Window Size
%     function changeSizeWindow(~, ~)
%         val = get(sH.menuSizeWindow, 'Value');
%         smallScreen = val -1;
%         updatePositionsUI(sH, getPositionsUI(smallScreen), smallScreen);
%         displayImage;
%         sH.jFig.getAxisComponent.requestFocus;
%     end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Enable general options
    function enableOptions
%         set(sH.option1, 'Enable', 'on');
%         set(sH.option2, 'Enable', 'on');
%         set(sH.option3, 'Enable', 'on');
%         set(sH.option4, 'Enable', 'on');

%         set(sH.buttonSeeds, 'Enable', 'on');
%         set(sH.buttonAdd, 'Enable', 'on');
%         set(sH.buttonDel, 'Enable', 'on');
%         set(sH.buttonRename, 'Enable', 'on');
%         set(sH.checkAllZ, 'Enable', 'on');
%         set(sH.check3D, 'Enable', 'on');
%         set(sH.checkFlipUD, 'Enable', 'on');
%         set(sH.checkFlipLR, 'Enable', 'on');
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Enable tracking options
    function enableTracking
%         set([sH.toggleSegm,           ...
%             sH.toggleLabel,           ...
%             sH.toggleGVF,             ...
%             sH.buttonTrackAll,        ...
%             sH.buttonTrackSel,        ...
%             sH.checkRegister,         ...
%             sH.buttonMerge,           ...
%             sH.textA,                 ...
%             sH.selectNeuron1,         ...
%             sH.selectNeuron2],        ...
%             'Enable', 'on');
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Disable tracking options
    function disableTracking %#ok<DEFNU>
%         set([sH.toggleSegm,           ...
%             sH.toggleLabel,           ...
%             sH.toggleGVF,             ...
%             sH.buttonTrackAll,        ...
%             sH.buttonTrackSel,        ...
%             sH.checkRegister,         ...
%             sH.buttonMerge,           ...
%             sH.textA,                 ...
%             sH.selectNeuron1,         ...
%             sH.selectNeuron2],        ...
%             'Enable', 'off');
%         
%         set([sH.toggleLabel,          ...
%             sH.toggleSegm,            ...
%             sH.toggleGVF],            ...
%             'Value', 0);
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Neuron clicked from the image
    function ImageClick(~, ~)
        
        if sG.labelBehaviors, return, end
        
        [r, c] = getCoordinates;
        
        if flgAddNeuron
            appendNeuron(r, c, valZ, false);

            updateList;
            initializeOverlays;
            movePlot;
            enableTracking;
            displayImage;

            flgAddNeuron = false;
        elseif flgAddWorm
            free(sH.textBehavior);
            appendWorm(r, c);
            updateList;
            lenList =  length( get(sH.listN, 'String') );
            set(sH.listN, 'Value', lenList);    % Select the worm just added
            hLines = plotBehaviors(hAxisBeh, hLines, worms(lenList).behaviors);
            initializeOverlays;
            displayImage;

            if flgAddBehaviors
                selectMenu([], [], '&Behavior', 'Label Behaviors');
            else
                selectMenu([], [], '&Behavior', 'Pointer Scroll');
            end
            flgAddWorm = false;
        else

            minDist = inf;
            minIdx = NaN;

            switch modeICE
                case 'acquireICE'
                    switch sG.layers
                        case 'max'
                            ndata = neuronsMip;
                        otherwise
                            ndata = neurons{valZ};
                    end
                    for ii = 1:numel(ndata)
                        neuron = ndata{ii};
                        tr = neuron.pos(valT, 1);
                        tc = neuron.pos(valT, 2);
                        distance = eucl_dist(r, c, tr, tc);
                        if distance < minDist
                            minDist = distance;
                            minIdx = ii;
                        end
                    end
                case 'behaviorICE'
                    for ii = 1:size(worms, 2)
                        tc = worms(ii).coordinatesX;
                        tr = worms(ii).coordinatesY;
                        distance = eucl_dist(r, c, tr, tc);
                        if distance < minDist
                            minDist = distance;
                            minIdx = ii;
                        end
                    end
                    if ~isnan(minIdx)
                        idxWorm = minIdx;
                        hLines = plotBehaviors(hAxisBeh, hLines, worms(idxWorm).behaviors);
                    end
            end

            if ~isnan(minIdx)
%                 updateList;
                set(sH.listN, 'Value', minIdx);                             % Select the worm
%                 displayImage;
                movePlot;
            end
        end
        sH.jFig.getAxisComponent.requestFocus;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function [r, c] = getCoordinates
        
            cp = get(gca, 'CurrentPoint');
            r = cp(1, 2);
            c = cp(1, 1);
            
            % Checks for image flipping;
            if sG.flipVertical
                r = dimDispY - r;
            end
            if sG.flipHorizontal
                c = dimDispX - c;
            end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function createROI(~, ~)
        
        if ~strcmp(sG.modeImage, 'RAM')
            prt('Switching to RAM mode...');
            selectMenu([], [], '&Image Mode', '&RAM');
        end

        % Create a status of ROI if it doesn't exist
        if ~isfield(sG, 'showROI')
            sG.showROI = true;
        end
        
        if sG.showROI
            % Get and check the size of ROI
            radiusROI = sG.sizeROI; % get(sH.editSizeROI, 'String') );
            if ~isempty(radiusROI)
                if radiusROI < 1
                    radiusROI = 1;
                elseif radiusROI > dimDispX
                    radiusROI = dimDispX;
                end
            else
                radiusROI = 100;
            end
            
            rangeX = get(sH.axisImage, 'XLim');
            rangeY = get(sH.axisImage, 'YLim');
            
            % Create ROI in the middle of the images
            rangeROI = [mean(rangeX)-radiusROI mean(rangeY)-radiusROI radiusROI*2 radiusROI*2];
            switch sG.typeROI % get(sH.popupTypeROI, 'Value')
                case 'ellipse'
                    sH.ROI = imellipse(sH.axisImage, rangeROI);
                case 'rectangle'
                    sH.ROI = imrect(sH.axisImage, rangeROI);
            end
            addNewPositionCallback(sH.ROI, @callbackROI);
            prt('% 4.1f', rangeROI);
            dragzoomMod(sH.axisImage, 'off');
%             sG.showROI = false;
            sH.jMenuItems{9, 2}.setIcon( javax.swing.ImageIcon(paths.iconChecked) ); % ROI
        else
            xlim(sH.axisImage, rangeDefaultX);
            ylim(sH.axisImage, rangeDefaultY);            
            dragzoomMod(sH.axisImage, 'on', hFunctions);            
            xlim(sH.axisImage, rangeX);
            ylim(sH.axisImage, rangeY);
            % Delete the previous ROIs
            if issafe('sH.ROI')
                free(sH.ROI);
            end
%             sG.showROI = true;
            sH.jMenuItems{9, 2}.setIcon( javax.swing.ImageIcon(paths.iconUnchecked) ); % ROI
        end
        maskROI = false(dimDispX, dimDispY);
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function callbackROI(~, ~)
        sH.jFig.getAxisComponent.requestFocus;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function changeShapeROI(~, ~)
        for m = 1:3
            updateMenuIcon(m, 2, sH.jMenuItemsSub, false, paths);
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function measureIntensity(~, ~)
        
        flgPlot = true;
        
        if issafe('sH.ROI')
            % Create a mask from ROI
            maskROI(:, :) = createMask(sH.ROI);
            
            % Mask boundaries
            c1 = find(any(maskROI, 1), 1, 'first');
            c2 = find(any(maskROI, 1), 1, 'last');
            r1 = find(any(maskROI, 2), 1, 'first');
            r2 = find(any(maskROI, 2), 1, 'last');
            
            sizeND = size(ND{valZ}(:, 1), 1);
            intensityMean = nan(dimTP, dimZ, 2, 'double');
            areaROI = sum(sum(maskROI));
            
            % Load all frames to RAM if they are not already.
            if ~strcmp(sG.modeImage, 'RAM') % get(sH.selectModeImage, 'Value') ~= 2
                for c = 1:2
                    fd = fopen(pathICE{c}, 'r');
                    im = loadIcePartial(fd, dimX, dimY, dimZ, dimTP, r1, c1, valZ, r2-r1, c2-c1);
                    intensityMean(:, valZ, c) = sum( sum(im) ) / areaROI;
                    fclose(fd);
                end
            else
                
                progressBar(flgGUI, sH, 'initiate', 'Measuring Pixel Intensities...');
                switch sG.selectZsToMeasure % get(sH.popupMeasureZ, 'Value') == 1
                    case 'current'
                        selectedZ = valZ; % current Z
                    case 'all'
                        selectedZ = 1:dimZ; % all Z
                end
                
                
                
                for z = selectedZ
                    for fr = 1:sizeND
                        %                     frND = ND{z}(fr, 1);
                        frND = getCurrentFrameFromND(z, fr);
                        % Get mean pixel intensities of ROI for left and right images
                        for RG = 1:2

                            im = imgRAM{RG}(r1:r2, c1:c2, frND(RG) ); % Copy only the ROI area

                            intensityMean(fr, z, RG) = sum( sum(im) ) / areaROI;
                        end
                    end
                    progressBar(flgGUI, sH, 'iterate', [], z, dimZ);
                    
                end
                
            end
            timeElapsed(:, valZ) = ND{valZ}(:, 4);
            
                
            switch sVar.modeAcquisition % get(sH.popupMeasureZ, 'Value') == 3
                case 'BCECF'
                    figure;plot(timeElapsed, intensityMean(:,:,2) ./ intensityMean(:,:,1), 'Marker','*');
                    figure;plot(timeElapsed, intensityMean(:,:,1), 'Marker','*');
                    figure;plot(timeElapsed, intensityMean(:,:,2), 'Marker','*');
                otherwise
                    if flgPlot
                        h = figure;plot(timeElapsed, intensityMean(:,:,1), 'Marker','*');
                        h = figure;plot(timeElapsed, intensityMean(:,:,2), 'Marker','*');
                        appendAsNeuron;
                        scrollableTimeSeriesGateway;
                    end
            end

            save([pathFolder, '\ROI.mat'], 'intensityMean', 'timeElapsed');
            selectMenu([], [], '&Analysis', 'RO&I');
            progressBar(flgGUI, sH, 'terminate', 'Measuring Done.');
        else
            progressBar(flgGUI, sH, 'terminate', 'Create a ROI first.');
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function appendWorm(row, col)

        if isempty(worms)
            num = size(worms, 1) + 1;
        else
            num = max([worms.wormNumber]) + 1;
        end
%         else
%             idx = size(worms, 1) + 1;
%         end
        worms(end+1).timepoints = ND{1}(:, 4);
        worms(end).behaviors = nan(size(ND{1}(:, 4), 1), 1);
        worms(end).coordinatesX = col;
        worms(end).coordinatesY = row;
        worms(end).wormNumber = num;
        worms(end).name = ['worm', num2str(num)];
        
%         set(sH.listN,'Value', idxWorm);
%         updateList;
        
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function markWormAsX
        worms(idxWorm).wormNumber = nan;
        worms(idxWorm).name = 'X';
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function demarkWorm
        if ~isnan(worms(idxWorm).wormNumber)
            return;
        end
        num = max([worms.wormNumber]) + 1;
        worms(idxWorm).wormNumber = num;
        worms(idxWorm).name = ['worm', num2str(num)];
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function nextWorm(D)
        N = numel(worms);
        idxWorm = idxWorm + D;
        if idxWorm < 1
            idxWorm = 1;
        elseif idxWorm > N
            idxWorm = N;
        end
        
        set(sH.listN, 'Value', idxWorm);
%         updateList;
%         movePlot;
%         displayImage;
%         hLines = plotBehaviors(hAxisBeh, hLines, worms(idxWorm).behaviors);
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function appendAsNeuron(~, ~)
        
        if any(maskROI(:))
            sP = regionprops(maskROI, 'Centroid');
            
            switch sG.selectZsToMeasure % get(sH.popupMeasureZ, 'Value') == 1
                case 'current'
                    selectedZ = valZ; % current Z
                otherwise
                    selectedZ = 1:dimZ; % all Z
            end
            
            for sz = selectedZ
                appendNeuron(sP.Centroid(2), sP.Centroid(1), sz, true);
            end
            
%             set(sH.SelectZ, 'Value', valZ);
            updateList;
            initializeOverlays;
            movePlot;
            enableTracking;
            displayImage;
            prt('Added as Neuron');
        else
            progressBar(flgGUI, sH, 'terminate', 'Measure pixel intensities first.');
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function appendNeuron(row, col, plane, flgAllFrames)
               
        % Read names of all the neurons, and get the max neuron number
        names = readNeurons(neurons(plane), 'name');
        if cellfun(@isempty, names(1))
            nameNew = 'neuron1';
        else
            neuronNumbers = cellfun(@(x) regexprep(x, '[^0-9]', ''), names{:}, 'UniformOutput', false);
            neuronNumbers( cellfun(@isempty, neuronNumbers) ) = [];
            maxNeuronNumber = max( cellfun(@str2num, neuronNumbers) );
            nameNew = ['neuron', num2str(maxNeuronNumber + 1)];
        end
        
        if flgAllFrames
            pos(1:dimTP, :) = repmat([row, col], dimTP, 1);
            
            segm_crop_pos(1:dimTP, 1) = repmat(find(any(maskROI,2), 1, 'first'), dimTP, 1);
            segm_crop_pos(1:dimTP, 2) = repmat(find(any(maskROI,2), 1, 'last'), dimTP, 1);
            segm_crop_pos(1:dimTP, 3) = repmat(find(any(maskROI,1), 1, 'first'), dimTP, 1);
            segm_crop_pos(1:dimTP, 4) = repmat(find(any(maskROI,1), 1, 'last'), dimTP, 1);
            segm(:, :, 1:dimTP) = repmat(...
                  maskROI( segm_crop_pos(1, 1):segm_crop_pos(1, 2), segm_crop_pos(1, 3):segm_crop_pos(1, 4) ), 1, 1, 1, dimTP);                                
            int_ratio = intensityMean(:, plane, 2) ./ intensityMean(:, plane, 1);
            int_g = intensityMean(:, plane, 2);
            int_r = intensityMean(:, plane, 1);
            frInit = 1;
        else
            pos = zeros(dimTP, 3);
            pos(valT, 1) = row;
            pos(valT, 2) = col;
            pos(valT, 3) = plane;
            
            segm = [];
            segm_crop_pos = [];
            int_ratio = zeros(dimTP, 1);
            int_g = zeros(dimTP, 1);
            int_r = zeros(dimTP, 1);
            frInit = valT;
        end
        
        neuron = struct(                            ...
            'name',         nameNew,                ...
            'z',            plane,                  ...
            'init_fr',      frInit,                 ...
            'pos',          pos,                    ...
            'segm',         segm,                   ...
            'segm_crop_pos', segm_crop_pos,         ...
            'int_ratio',    int_ratio,              ...
            'int_g',        int_g,                  ...
            'int_r',        int_r);

        neurons{plane} = cat(2, neurons{plane}, {neuron});
        listNeurons{plane} = cat(1, listNeurons{plane}, nameNew);
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function showTemperatures(~, ~)
        posFig = get(sH.fig, 'Position');
        posX = posFig(1) + posFig(3) + 15;
        hF = figure('Position', [posFig(1), posFig(2) + posFig(4) + 90, 500, 150]);
        
        % Plot temperatures
        sH.axisTempSA = axes('Parent', hF, 'Units','normalized', 'Position', [0.05, 0.15, 0.9, 0.7]);
        
        switch sVar.modeHeater
            case 'TEC'
                sH.axisTempSA = plotTemperatures(sVar, sH.axisTempSA);
            case 'zap'
                [amplitude, time] = parseZapPlan(sVar.planLaser, sVar.zapPower, sVar.duration, sVar.zapDuration);
                plot(sH.axisTempSA, time, amplitude);
                xlim(sH.axisTempSA, [min( sVar.infoND(:, 4) ), max( sVar.infoND(:, 4) )]);
                ylim(sH.axisTempSA, [0 - max(amplitude) * 0.1, max(amplitude) * 1.1]);
                title(sH.axisTempSA, sprintf('Laser Plan'));
            case 'IR'
%                 sVar.tempOven(:, 1) = nan( size( sVar.tempOven(:, 1) ) );
                sH.axisTempSA = plotTemperatures(sVar, sH.axisTempSA);
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function showHeatmap
        sVar;
        
        c = cellfun(@(x) cat(2, x{:}), neurons, 'un', false);
        n = cat(2, c{:});
        

        numNr = length(n);
        numTp = length(n(1).int_ratio);
%         map = nan(numNr, numTp);
        map = cat(1, n(:).int_ratio);
        
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function changeModeImage(~, ~, flgRegister)

        if ~exist('flgRegister', 'var')
            flgRegister = false;
        end
        
        % Close all file handles
        closeAllFiles;
        
        % Close RAM images
        if exist('imgRAM', 'var')
            clear imgRAM;
        end
        
        sG.safeWheel = false;

        free(hImage);
        initialize(pathICE{1});
        loadLabels
        initializeOverlays;
        
        sH.jFig.getAxisComponent.requestFocus;
        
        % If this function was invoked from registerImages to load images to RAM, then initiate
        % image registration at this point
        if flgRegister
            registerImagesGateway;
        end
        
        sG.safeWheel = true;
        
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function saveTimeSeries(~, ~)
         % Choose the file (will append if it already exists)
        [file, path, x] = uiputfile( ...
                {'*.mat', 'MATLAB Data File (*.mat)'; '*.*', 'All Files' }, 'Save intensity time series', 'intensity.mat');
        
        if x == 0   % If no file selected
            return;
        end
        
        % Prompt the user to choose the name that the data will be saved as
        name = inputdlg('Variable name: ', 'Name', 1, {file(1:end-4)});
        
        if numel(name) < 1  % If name not entered
            name = file(1:end-4);
        else
            name = name{1};
        end
        
        varname = genvarname(name); %#ok<DEPGENAM> % Construct valid variable name
        
        saveStruct = struct(varname, intensity_ratio(valZ,:)); %#ok<NASGU>
        
        if exist([path,file], 'file')   % If variable file already exists
            save([path,file], '-struct', 'saveStruct', varname, '-append');
        else                            % Otherwise make a new file
            save([path,file], '-struct', 'saveStruct', varname);
        end
        sH.jFig.getAxisComponent.requestFocus;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Save and Load Analysis
    function saveLabels(~, ~)
        
        switch modeICE
            case 'acquireICE'
                lb = 'neurons';
            case 'behaviorICE'
                lb = 'worms';
        end
        
%         if exist([pathFolder, '\', [lb, '.mat'] ], 'file')
%             choice = questdlg(['Are you sure you want to replace the saved ', lb, ' labels?'], ...
%                 'Overwrite Confirmation', 'Yes', 'No', 'Yes');
%             switch choice
%                 case 'Yes'
%                     save([pathFolder, '\', [lb, '.mat']], lb);
%                 case 'No'
%                     return
%             end
%         else
%             save([pathFolder, '\', [lb, '.mat']], lb);
%         end
        
        save([pathFolder, '\', [lb, '.mat']], lb);
        prt('Labels Saved');
        
        flgDataModified = false;
        sH.jFig.getAxisComponent.requestFocus;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function loadLabels(~, ~)
        if exist([pathFolder, '\', 'neurons.mat'], 'file')
            if any(cellfun(@isempty, neurons))
                sTemp = load([pathFolder, '\','neurons.mat']);
                neurons = sTemp.neurons;
                listNeurons = readNeurons(neurons, 'name'); % Read names of all the neurons
                enableTracking;
                enableOptions;
            else
                choice = questdlg('Are you sure you want to overwrite the existing neurons?', ...
                    'Overwrite Confirmation', 'Yes', 'No', 'No');
                switch choice
                    case 'Yes'
                        sTemp = load([pathFolder, '\','neurons.mat']);
                        neurons = sTemp.neurons;
                        listNeurons = readNeurons(neurons, 'name'); % Read names of all the neurons
                    case 'No'
                        return
                end
            end
        elseif exist([pathFolder, '\', 'worms.mat'], 'file')
            if any(cellfun(@isempty, neurons))
                s = load([pathFolder, '\','worms.mat']);
                worms = s.worms;
            else
                choice = questdlg('Are you sure you want to overwrite the existing worms?', ...
                    'Overwrite Confirmation', 'Yes', 'No', 'No');
                switch choice
                    case 'Yes'
                        s = load([pathFolder, '\','worms.mat']);
                        worms = s.worms;
                    case 'No'
                        return
                end
            end            
        end

        updateList
        sH.jFig.getAxisComponent.requestFocus;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Callback function for file system change to update progress bar during
% parfor loops
    function eventhandlerChanged(~, ~)
        
        list = dir(dirCount);
        numAnalyzed = numel(list) - 2;
        fraction = ( numAnalyzed / dimTP ) * 100;
        sH.statusBar.setText('Registering images ...');
        sH.progressBar.setValue(fraction);
        sH.progressBar.setString([num2str(fraction, '%3.0f'), '%']);
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function selectMenu(obj, ~, parent, label)
        
        if exist('obj', 'var')
            fieldH = []; fieldHCtrl = []; selectCtrl = [];
            if ~exist('parent', 'var'); % Came from UI controls
                label = get(obj, 'Label');
                parent = get(get(obj, 'Parent'), 'Label');
            else
                obj = findobj(sH.fig, 'Label', label);
            end
            objP = get(obj, 'Parent');
        end
        
        switch parent
            case '&File'
                switch label
                    case '&Open ICE'
                        openFile;
                    case '&Save Labels'
                        saveLabels;
                    case '&Load Labels'
                        loadLabels;
                    case 'Save &Time-series'
                        saveTimeSeries;
                    case '&Quit'
                        quitFile;
                end, return
            case '&Analysis'
                col = 2; jMenu = 'jMenuItems'; ui = 'check';
                switch label
                    case '&Show Time-series'
                        scrollableTimeSeriesGateway; return
                    case 'Show &Heatmap'
                        showHeatmap; return
                    case '&Register Images'
                        registerImagesGateway; return
                    case 'Use &CUDA'
                        fieldG = 'useCUDA'; fieldHCtrl = 'checkGPU'; row = 5;
                    case '&Temperatures'
                        showTemperatures; return
                    case 'RO&I'
                        fieldG = 'showROI'; fieldHCtrl = 'buttonROI'; row = 9;
                        updateUIs;
                        createROI; return
                    case '&Measure'
                        measureIntensity; return
                    case '&Add as Neuron'
                        appendAsNeuron; return
                    case '&Export Movie'
                        makeMovieGateway; return
                end
                updateUIs;
            case '&Tracking'
                col = 3; jMenu = 'jMenuItems'; ui = 'check';
                switch label
                    case '&Get Seeds'
                        getSeedsGateway; return
                    case 'For All &Z'
                        fieldG = 'forAllZ'; fieldHCtrl = 'checkAllZ'; row = 2;
                    case 'Track &All'
                        trackAllGateway; return
                    case 'Track in 3&D'
                        fieldG = 'track3D'; fieldHCtrl = 'check3D'; row = 5;
                    case '&Register before Track'
                        fieldG = 'registerBeforeTrack'; fieldHCtrl = 'checkRegister'; row = 6;
                    case 'Track &Selected'
                        trackSelGateway; return
                end
                updateUIs;
            case '&View'
                col = 4; jMenu = 'jMenuItems'; ui = 'check';
                switch label
                    case '&Autoscale'
                        autoscaleRGB; return
                    case 'Flip &Vertically'
                        fieldG = 'flipVertical'; fieldH = 'checkFlipVertical'; row = 3;
                    case 'Flip &Horizontally'
                        fieldG = 'flipHorizontal'; fieldH = 'checkFlipHorizontal'; row = 4;
                    case 'Show &Regions'
                        fieldG = 'showRegions'; fieldHCtrl = 'toggleSegm'; row = 6;
                    case 'Show &Labels'
                        fieldG = 'showLabels'; fieldHCtrl = 'toggleLabel'; row = 7;
                    case 'Show &GVF'
                        fieldG = 'showGVF'; fieldHCtrl = 'toggleGVF'; row = 8;
                    case 'Toggle &Overlays'
                        toggleOverlays; return
                end
                updateUIs; updateDisplay;
            case '&Layers'
                col = 5; jMenu = 'jMenuItems'; fieldG = 'layers'; ui = 'radio';
                colorCustom = [0 0 1];
                switch label
                    case '&Red'
                         radio = 'red'; fieldH = 'option1'; row = 1;
                         colorSelectedPointEdge = 'g'; colorSelectedPointFace = 'r';
                         colorPointsEdge = 'r'; colorPointsFace = 'g';
                    case '&Green'
                         radio = 'green'; fieldH = 'option2'; row = 2;
                         colorSelectedPointEdge = 'g'; colorSelectedPointFace = 'r';
                         colorPointsEdge = 'r'; colorPointsFace = 'g';                        
                    case 'RG&B'
                         radio = 'RGB'; fieldH = 'option3'; row = 3;
                         colorSelectedPointEdge = 'w'; colorSelectedPointFace = colorCustom;
                         colorPointsEdge = colorCustom; colorPointsFace = 'w';                        
                    case '&Max'
                         radio = 'max'; fieldH = 'option4'; row = 4;
                         colorSelectedPointEdge = 'w'; colorSelectedPointFace = colorCustom;
                         colorPointsEdge = colorCustom; colorPointsFace = 'w';                        
                end

                updateUIs; updateDisplay;
                if issafe('sH.figTS')
                    free(sH.figTS);
                    sH.figTS = [];
                end
            case '&Neurons'
                switch label
                    case '&Add Neuron'
                        addNeuron;
                    case '&Delete Neuron'
                        delNeuron;
                    case '&Rename Neuron'
                        renameNeuron;
                end, return
            case '&Behavior'
                col = 7; jMenu = 'jMenuItems';
                switch label
                    case 'Pointer Scroll'
                        row = 1; fieldG = 'scrollPointer'; ui = 'check';
                        startMouseTimer;
                        updateUIs;
                    case 'Label Behaviors'
                        row = 2; fieldG = 'labelBehaviors'; ui = 'check';
                        toggleLabelBehavior;
                        updateUIs;
                    case 'Add Worm'
                        addWorm;
                        if sG.scrollPointer
                            selectMenu([], [], '&Behavior', 'Pointer Scroll');
                        end
                    case 'Delete Worm'
                        deleteWorm;
                    case 'Show Behaviors'
                        row = 4; fieldG = 'showBehaviors'; ui = 'check';
                        if ~issafe('hFigBeh')
                            createFigureBehavior;
                        end
                    case 'Add Behaviors'
                        addWorm;
                        if sG.scrollPointer
                            selectMenu([], [], '&Behavior', 'Pointer Scroll');
                        end
%                         flgAddBehaviors = true;
                    case 'Mark X'
                        markWormAsX;
                    case 'Demark X'
                        demarkWorm;
                    case 'Previous Worm'
                        nextWorm(-1);
                    case 'Next Worm'
                        nextWorm(1);
                end
                displayImage;
            case '&Image Mode'
                col = 1; jMenu = 'jMenuItemsSub'; fieldG = 'modeImage'; selectCtrl = 'selectModeImage'; ui = 'radio';
                switch label
                    case '&Disk'
                        radio = 'uint16'; row = 1; valSelect = 3;
                    case '&RAM'
                        radio = 'RAM'; row = 2; valSelect = 2;
                    case '&Mapped'
                        radio = 'map'; row = 3; valSelect = 1;
                end
                sG.modeImage = radio; updateUIs; changeModeImage;
            case 'S&hape'
                switch label
                    case '&Ellipse'
                        changeShapeROI;
                    case '&Rectangle'
                        changeShapeROI;
                end
        end
%-----------------------------------------------------------------------------------------------------------------------        
        function updateUIs
            switch ui
                case 'check'
                    toggleStateGUI(fieldG);
                    updateMenuIcon(row, col, sH.(jMenu), sG.(fieldG), paths);
                    if ~isempty(fieldH)
                        set( sH.(fieldH), 'Value', sG.(fieldG) ); % Update checkbutton UI on main figure
                    end
                    if ~isempty(fieldHCtrl) && issafe('sHCtrl.figCtrl')
                        set( sHCtrl.(fieldHCtrl), 'Value', sG.(fieldG) ); % Update radiobutton UI on ctrl panel
                    end
                case 'radio'
                    for m = 1:numel( get(objP, 'Children') )
                        updateMenuIcon(m, col, sH.(jMenu), false, paths);
                    end
                    updateMenuIcon(row, col, sH.(jMenu), true, paths);
                    sG.(fieldG) = radio;
                    
                    if ~isempty(fieldH)
                        set( sH.(fieldH), 'Value', true ); % Update checkbutton UI on main figure
                    end
                    if ~isempty(fieldHCtrl) && issafe('sHCtrl.figCtrl')
                        set( sHCtrl.(fieldHCtrl), 'Value', sG.(fieldG) ); % Update radiobutton UI on ctrl panel
                    end
                    if ~isempty(selectCtrl) && issafe('sHCtrl.figCtrl')
                        set( sHCtrl.(selectCtrl), 'Value', valSelect ); % Update select UI on ctrl panel
                    end
            end
        end
%-----------------------------------------------------------------------------------------------------------------------
        function updateDisplay
            initializeOverlays;
            displayImage;
            sH.jFig.getAxisComponent.requestFocus;
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function GUI2menu(obj, ~)
        tag = get(obj, 'Tag');
        
        % Conversion of UI tag to menu command
        switch tag
            case 'checkFlipVertical'
                selectMenu([], [], '&View', 'Flip &Vertically');
            case 'checkFlipHorizontal'
                selectMenu([], [], '&View', 'Flip &Horizontally');
            case 'toggleSegm'
                selectMenu([], [], '&View', 'Show &Regions');
            case 'toggleLabel'
                selectMenu([], [], '&View', 'Show &Labels');
            case 'toggleGVF'
                selectMenu([], [], '&View', 'Show &GVF');
            case 'buttonGroupLayers'
                children = get(obj, 'Children');
                for c = 1:numel(children)
                    if get(children(c), 'Value'), radio = get(children(c), 'Tag'); end
                end
                switch radio
                    case 'option1'
                        selectMenu([], [], '&Layers', '&Red');
                    case 'option2'
                        selectMenu([], [], '&Layers', '&Green');
                    case 'option3'
                        selectMenu([], [], '&Layers', 'RG&B');
                    case 'option4'
                        selectMenu([], [], '&Layers', '&Max');
                end
            case 'selectModeImage'
                val = get(obj, 'Value');
                if val == 1
                    mode = '&Mapped';
                elseif val == 2
                    mode = '&RAM';
                elseif val == 3
                    mode = '&Disk';
                end
                selectMenu([], [], '&Image Mode', mode);
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function toggleStateGUI(field)
        if ~exist('field', 'var')
            return
        end
        
        if ~isfield(sG, field)
            sG.(field) = false;
        end

        if sG.(field)
            sG.(field) = false;
        else
            sG.(field) = true;
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function setValuesControlPanel(item, value)
       if issafe('sHCtrl.figCtrl')
           set(sHCtrl.(item), 'Value', value);
       end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function selectList(~, ~)
        
        if sG.labelBehaviors
            set(sH.listN, 'Value', idxWorm);  % Force the worm list selection to original state when behavior mode is started
            sH.jFig.getAxisComponent.requestFocus;
            return
        end
        
        updateList;
        movePlot;
        displayImage;
        switch modeICE
            case 'behaviorICE'
                idxWorm = get(sH.listN, 'Value');
                hLines = plotBehaviors(hAxisBeh, hLines, worms(idxWorm).behaviors);
        end
        sH.jFig.getAxisComponent.requestFocus;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     function selectZ(~, ~)  % Added 140116
%         set(sH.listN, 'Value', 1);
%         updateList;
%         sH.jFig.getAxisComponent.requestFocus;
%     end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function addWorm(~, ~)
        if ~issafe('hAxisBeh')
            selectMenu([], [], '&Behavior', 'Show Behaviors');
        end
        flgAddBehaviors = true;
        flgAddWorm = true;
        flgDataModified = true;
        sH.textBehavior = text(0, 3, 'Select a Worm', 'color', [1 1 1], 'Parent', hAxisBeh, 'FontSize', 25);
        prt('Select a worm');
        sH.jFig.getAxisComponent.requestFocus;        
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function deleteWorm(~, ~)
        idx = get(sH.listN, 'Value');

        if idx && ~isempty(worms)
            worms(idx) = [];
            idxWorm = idx - 1;
            updateList;
            set(sH.listN, 'Value', 1);
            displayImage;
        end
        flgDataModified = true;
        sH.jFig.getAxisComponent.requestFocus;        
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function addNeuron(~, ~)
%         msgbox('Click on the initial position of the neuron', 'Locate the neuron')
        flgAddNeuron = 1;
        % Proceed to function ImageClick
        flgDataModified = true;
        sH.jFig.getAxisComponent.requestFocus;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function delNeuron(~,~)
        index = get(sH.listN, 'Value');
%         z = get(sH.SelectZ, 'Value');  % Added 140116
        z = valZ;

        if index && ~isempty(neurons{z})    % Added 140116
            neurons{z}(index) = [];
            listNeurons = readNeurons(neurons, 'name'); % Read names of all the neurons
%             listNeurons{z}(index) = [];
            
%             if ~numel(listNeurons{z})
%                 listNeurons{z} = [];  % Preserve cell structure
%             end
            updateList;
            set(sH.listN, 'Value', max(1,min(index, numel(listNeurons{z}))));
            sG.selectNeuronIndex1 = max(min(index, numel(listNeurons{valZ})),1);
            sG.selectNeuronIndex2 = max(min(index, numel(listNeurons{valZ})),1);
%             set(sH.selectNeuron1, 'Value', max(min(index, numel(listNeurons{z})),1));
%             set(sH.selectNeuron2, 'Value', max(min(index, numel(listNeurons{z})),1));
            displayImage;
        end
        flgDataModified = true;
        sH.jFig.getAxisComponent.requestFocus;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function renameNeuron(~, ~)
        % Added 140116
        index = get(sH.listN, 'Value');
%         z = get(sH.SelectZ, 'Value');
        z = valZ;
        
        if index && ~isempty(neurons{z})
            old_name = neurons{z}{index}.name;
            new_name = inputdlg2('New name: ', ['Rename ', old_name], 1, {old_name});
            
            if ~isempty(new_name) && ~strcmp(old_name, new_name)
                if strcmp(new_name, '00')
                    new_name = 'neuron00';
                else
                    new_name = upper(new_name{1});
                end
                neurons{z}{index}.name = new_name;
                listNeurons = readNeurons(neurons, 'name'); % Read names of all the neurons
%                 listNeurons{z}{index} = new_name;
                updateList;
                displayImage;
                flgDataModified = true;
            end
        end
        sH.jFig.getAxisComponent.requestFocus;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function dimN = getLabelsMip()
        labels = []; neuronsMip = []; dimN = 0; nr = []; nc = [];
        for z = 1:dimZ
            for n = 1:numel(neurons{z}(:))
                if length(neurons{z}{n}.name) < 3 ||...
                    ~strcmp(neurons{z}{n}.name(1:3),'neu')
                    labels = [labels; {neurons{z}{n}.name}];
                    neuronsMip = [neuronsMip, neurons{z}(n)];
                    nr = [nr; neurons{z}{n}.pos(valT, 1)];
                    nc = [nc; neurons{z}{n}.pos(valT, 2)];
                    dimN = dimN + 1;
                end
            end
        end
        set(sH.listN, 'Value', 1);
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function updateList(listIn)
        
        if exist('listIn', 'var')
            labels = listIn;
        elseif strcmp(modeICE, 'acquireICE')
            switch sG.layers
                case 'max'
%                     getLabelsMip;
                    
                otherwise
                    labels = listNeurons{valZ};
            end
        elseif strcmp(modeICE, 'behaviorICE')
            if ~isempty(worms)  && isfield(worms, 'name')
                labels = {worms.name}';
            else
                labels = [];
            end
        end
        
        if ~isempty(labels)   % If the list is nonempty
            
            set(sH.listN, 'String', labels);
            sG.selectNeuron1 = labels;
            sG.selectNeuron2 = labels;
        else
            sG.selectNeuron1 = '(Empty)';
            sG.selectNeuron2 = '(Empty)';
            set(sH.listN, 'String', '(Empty)')
        end
        sG.selectNeuronIndex1 = '(Empty)';
        sG.selectNeuronIndex2 = '(Empty)';
        
        sH.jFig.getAxisComponent.requestFocus;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function mergeNeuron(~, ~)
        % Extract the indices of the neurons to be combined
        neuron1 = sG.selectNeuronIndex1;
        neuron2 = sG.selectNeuronIndex2;
        
        % If the indices are the same, or no neurons present, nothing to do
        if (neuron1 == neuron2) || ...
           isempty(listNeurons{valZ})
            return
        end
        
        % Extract the data for each neuron
        ndata = neurons{valZ};
        init_fr1 = ndata{neuron1}.init_fr;  % initial frame of neuron1
        init_fr2 = ndata{neuron2}.init_fr;  % initial frame of neuron2
        
        merged_init_fr = min(init_fr1, init_fr2);   % Merged
        pos1 = ndata{neuron1}.pos;
        pos2 = ndata{neuron2}.pos;
        segm1 = ndata{neuron1}.segm;
        segm2 = ndata{neuron2}.segm;
        int_ratio1 = ndata{neuron1}.int_ratio;
        int_ratio2 = ndata{neuron2}.int_ratio;
        int_g1 = ndata{neuron1}.int_g;
        int_g2 = ndata{neuron2}.int_g;
        int_r1 = ndata{neuron1}.int_g;
        int_r2 = ndata{neuron2}.int_g;
        
        
        for t = merged_init_fr:dimTP     % Loop through each time point
            if all(pos1(t,:)) && ~all(pos2(t,:))   % If neuron1 contains data missing from neuron2
                % Merge data
                pos2(t,:) = pos1(t,:);
                segm2(:,:,t) = segm1(:,:,t);
                int_ratio2(t) = int_ratio1(t);
                int_g2(t) = int_g1(t);
                int_r2(t) = int_r1(t);
            end
        end
        
        % Assign merged data
        neurons{valZ}{neuron2}.init_fr = merged_init_fr;
        neurons{valZ}{neuron2}.pos = pos2;
        neurons{valZ}{neuron2}.segm = segm2;
        neurons{valZ}{neuron2}.int_ratio = int_ratio2;
        neurons{valZ}{neuron2}.int_g = int_g2;
        neurons{valZ}{neuron2}.int_r = int_r2;
        
        % Destroy neuron1
        
        neurons{valZ}(neuron1) = [];
        listNeurons = readNeurons(neurons, 'name'); % Read names of all the neurons
%         listNeurons{valZ}(neuron1) = [];
        
%         if ~numel(listNeurons{valZ}) % Should not fire here
%             listNeurons{valZ} = [];  % Preserve cell structure
%         end
        
        index = get(sH.listN, 'Value');
        
        set(sH.listN, 'Value', min(index, numel(listNeurons{valZ})));
        sG.selectNeuronIndex1 = max(min(index, numel(listNeurons{valZ})),1);
        sG.selectNeuronIndex2 = max(min(index, numel(listNeurons{valZ})),1);
%         set(sH.selectNeuron1, 'Value', max(min(index, numel(n_list{valZ})),1));
%         set(sH.selectNeuron2, 'Value', max(min(index, numel(n_list{valZ})),1));
        
        updateList;
        displayImage;
        flgDataModified = true;
        sH.jFig.getAxisComponent.requestFocus;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function mouseMoved(src, ~)
%         prt(get(0,'PointerLocation') );
        if sG.enableMouseMove
%           get(0)
            obj = hittest(src); %determine which object is below the cursor
            %         prt(get(obj,'type'));
            if strcmp(get(obj,'type'),'image') %if over the image...
                point = get(sH.axisImage, 'CurrentPoint');
                posX = round(point(1,1));
                posY = round(point(1,2));
                
                if posX > dimDispX
                    posX = dimDispX;
                elseif posX < 1
                    posX = 1;
                end
                if posY > dimDispY
                    posY = dimDispY;
                elseif posY < 1
                    posY = 1;
                end
                switch sG.layers
                    case 'red'
                        intensityR = img16(posY, posX, 1);
                        intensityG = nan;
                        intensityB = nan;
                    case 'green'
                        intensityR = nan;
                        intensityG = img16(posY, posX, 2);
                        intensityB = nan;
                        
                    case {'RGB', 'max'}
                        if numCh >= 2
                            intensityR = img16(posY, posX, 1);
                            if size(img16, 3) > 1
                                intensityG = img16(posY, posX, 2);
                            end
                            if size(img16, 3) > 2
                                intensityB = img16(posY, posX, 3);
                            else
                                intensityB = nan;
                            end
                        end

                end
                updateDisplayStatus;
                
                if sG.enableScrollByMouse
                    
%                     weightDisplay = eDisp * 1;
                    if (toc(tScroll) > weightDisplay)
                        rangeX = get(sH.axisImage, 'XLim');
                        dimZoom = rangeX(2) - rangeX(1); 
                        valT = round(( posX - rangeX(1) ) / dimZoom * dimT);
                        set(sH.sliderT, 'Value', valT);
                        displayImage;
                        drawVline
                        tScroll = tic;  % Reset scroll timer
                    end
                    sH.jFig.getAxisComponent.requestFocus;
                end
            end
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function startMouseTimer
        if ~sG.scrollPointer
            
            sizeWin = getSizeWindows;
            widthWin = sizeWin.bounds.width; % Inner dimensions of the screen
            timerfind('Tag', 'mouseTimer'); % Delete any existing timer
            
            timerObj = timer('TimerFcn', @mouseTimer, 'Period', 0.01, 'ExecutionMode', 'fixedrate', 'Tag', 'mouseTimer');
            start(timerObj);
        else
            stop(timerObj);
            free(timerObj);
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function mouseTimer(~, ~)
        % this function is executed every time the timer object triggers
        %         global coords widthWin
        
        % read the coordinates
        c = get(0,'PointerLocation');
%                 prt(c);
        
        if any(c ~= coords)
            
%             valT = round((c(1) / widthWin) * dimTP);
            valT = round((c(1) / 1200) * dimTP);
%             prt(valT);
            if valT > dimTP
                valT = dimTP;
            elseif valT < 1
                valT = 1;
            end
            
            % Update images only when it has been long enough since the
            % last update. Updating too often causes jerky animation.
            if (toc(tScroll) > weightDisplay)

                set(sH.sliderT, 'Value', valT / dimTP);

                displayImage;
                updateDisplayStatus
                drawVline
                tScroll = tic;  % Reset scroll timer
                
            end
            sH.jFig.getAxisComponent.requestFocus;
        end
        coords = c;
    end % function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function toggleLabelBehavior
        free(sH.textModeBehavior);
        free(sH.textBehavior);
        if sG.labelBehaviors
            set(sH.fig, 'KeyPressFcn', []);


            assignKeyStrokes(sH.jMenuItems,    'main', 'play');
            assignKeyStrokes(sH.jMenuItemsSub, 'sub',  'play');
            prt('Behavior Mode OFF');
        else
            if isempty(worms)
                prt('Select at least one worm');
                return;
            end
            
            idxWorm = get(sH.listN,'Value'); % Store currently selected worm for behavioral labeling
            
            assignKeyStrokes(sH.jMenuItems,    'main', 'behavior');
            assignKeyStrokes(sH.jMenuItemsSub, 'sub',  'behavior');
            
            set(sH.fig, 'KeyPressFcn', hFunctions.keyPressed);
            
            selectMenu([], [], '&Behavior', 'Show Behaviors');
            sH.textModeBehavior = text(round(dimT/2), 3, 'Behavior Mode', 'HorizontalAlignment', 'center', ...
                 'color', 'white', 'Parent', hAxisBeh, 'FontSize', 25);

            prt('Behavior Mode ON');
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function createFigureBehavior
        idxWorm = get(sH.listN,'Value'); % This value will not change until behavior mode is finished
        pos = get(sH.fig, 'Position');
        pX = pos(1);
        pY = pos(2) + pos(4) + 60;
        hFigBeh = figure('Position', [pX pY pos(3) 150], 'NumberTitle','off', 'Name', 'Behaviors');
        set(hFigBeh, 'Color', [0 ,0, 0]);
        hAxisBeh = axes('Parent', hFigBeh, 'Units','normalized', 'Position', [0.02, 0.15, 0.96, 0.7]);
        set(hAxisBeh, 'Color', [0, 0, 0]);
        xlim([0 dimTP]); ylim([0 3]); set(hAxisBeh, 'Ytick', [], 'XColor', [1 1 1]);
        if ~isempty(worms)
            hLines = plotBehaviors(hAxisBeh, hLines, worms(idxWorm).behaviors);
        end
        figure(sH.fig);
        sH.jFig.getAxisComponent.requestFocus;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function labelBehavior(behavior)
        
        %         idxWorm = get(sH.listN,'Value');                                    % Selected worm
        if isempty(worms), return, end                                      % Exit the function if no worm is defined
        beh = worms(idxWorm).behaviors;
        %         if isempty(worms(idxWorm).behaviors), beh = nan(numel(worms), dimTP); end    % Create behavior matrix
        
        switch behavior
            case 'delete'
                idxFirst = findContinuous(valT, beh, -1);
                idxLast = findContinuous(valT, beh, 1);
                if isnan(idxFirst), return, end
                beh(idxFirst:idxLast) = nan;
                
%                 hLines = plotBehaviors(hAxisBeh, beh);
            otherwise
                
                if ~isnan( beh(valT) )
                    idxO = findContinuous(valT, beh, -1) - 1;
                else
                    idxO = valT;
                end
                idxTpLast = find(~isnan( beh(1: idxO) ), 1, 'last');        % Latest labeled TP before the current TP
                if isempty(idxTpLast)
                    idxTpLast = 1;                                                   % From the first TP
                else
                    idxTpLast = idxTpLast + 1;                                        % From the last behavior
                end
                
                if idxTpLast <= idxO
                    switch behavior
                        case 'forward'
                            beh(idxTpLast:idxO) = 1;
                        case 'reverse'
                            beh(idxTpLast:idxO) = 2;
                        case 'turn'
                            beh(idxTpLast:idxO) = 3;
                        case 'pause'
                            beh(idxTpLast:idxO) = 4;
                    end
                    

                end
                
        end
        
        hLines = plotBehaviors(hAxisBeh, hLines, beh);
        
        worms(idxWorm).behaviors = beh;
        flgDataModified = true;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function indOut = findContinuous(val, beh, step)   
        behT = beh(val);
        if isnan(behT), indOut = nan; return, end
        
        indOut = nan;
        idxC = val;
        while true
            if idxC <= 1
                indOut = 1;
                break;
            elseif idxC <= dimT && behT == beh(idxC);
                idxC = idxC + step;
            else
                indOut = idxC - step;
                break;
            end
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function keyPressed(~, event)
        
        free(sH.textBehavior);

        switch event.Key
            case 'f'
                labelBehavior('forward');
                sH.textBehavior = text(0, 3, 'Forward', 'color', [0.3 1 0.3], 'Parent', hAxisBeh, 'FontSize', 25);
                prt('Forward');
            case 'd'
                labelBehavior('reverse');
                sH.textBehavior = text(0, 3, 'Reverse', 'color', [1 0.3 0.3]', 'Parent', hAxisBeh, 'FontSize', 25);
                prt('Reverse');
            case 's'
                labelBehavior('turn');
                sH.textBehavior = text(0, 3, 'Turn', 'color', [0.5 0.5 1], 'Parent', hAxisBeh, 'FontSize', 25);
                prt('Turn');
            case 'a'
                labelBehavior('pause');
                sH.textBehavior = text(0, 3, 'Pause', 'color', [1 1 0.3], 'Parent', hAxisBeh, 'FontSize', 25);
                prt('Pause');
            case {'escape', 'r'}
                selectMenu([], [], '&Behavior', 'Label Behaviors');
%                 pause(0.1);
%                 sH.jMenu.setEnabled(true);
%             case 'e'
%                 selectMenu([], [], '&Behavior', 'Pointer Scroll');
            case {'backspace', 'delete'}
                labelBehavior('delete');
                sH.textBehavior = text(0, 3, 'Delete', 'color', [1 1 1], 'Parent', hAxisBeh, 'FontSize', 25);
                prt('Delete');

                
%             case 'w'
%                 if get(sH.checkFlipUD, 'Value')
%                     set(sH.checkFlipUD, 'Value', 0)
%                 else
%                     set(sH.checkFlipUD, 'Value', 1)
%                 end
%                 toggleClick;
%             case 'd'
%                 if get(sH.checkFlipLR, 'Value')
%                     set(sH.checkFlipLR, 'Value', 0)
%                 else
%                     set(sH.checkFlipLR, 'Value', 1)
%                 end
%                 toggleClick;
%             case 's'
%                 scrollableTimeSeriesGateway;
%             case 'z'
%                 saveAnalysis;
%             case 'q'
%                 quitFile;
%             case 'x'
%                 toggleOverlays;
%             case 'a'
%                 autoscaleRGB;
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Function Handles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function declareFunctionHandle

        % Function handles for calling nested functions from external functions
        hFunctions.initialize = @initialize;
        hFunctions.displayImage = @displayImage;
        hFunctions.selectList = @selectList;
%         hFunctions.selectZ = @selectZ;      % Added 140116
        hFunctions.addNeuron = @addNeuron;
        hFunctions.delNeuron = @delNeuron;
        hFunctions.renameNeuron = @renameNeuron;
%         hFunctions.toggleFlipStates = @toggleFlipStates;
%         hFunctions.optionChanged = @optionChanged;
        hFunctions.mergeNeuron = @mergeNeuron;
        hFunctions.openFile = @openFile;
        hFunctions.changeModeImage = @changeModeImage;
        hFunctions.registerImagesGateway = @registerImagesGateway;
        hFunctions.quitFile = @quitFile;
        hFunctions.showTimeSeries = @scrollableTimeSeriesGateway;
        hFunctions.saveTimeSeries = @saveTimeSeries;
        hFunctions.saveLabels = @saveLabels;
        hFunctions.loadLabels = @loadLabels;
        hFunctions.makeMovieGateway  = @makeMovieGateway;
        hFunctions.showTemperatures = @showTemperatures;
        hFunctions.createROI = @createROI;
        hFunctions.measureIntensity = @measureIntensity;
        hFunctions.addAsNeuron = @appendAsNeuron;
        hFunctions.getSeedsGateway = @getSeedsGateway;
        hFunctions.trackAllGateway = @trackAllGateway;
        hFunctions.trackSelGateway = @trackSelGateway;
        hFunctions.scrollSliderT = @scrollSliderT;
        hFunctions.scrollSliderZ = @scrollSliderZ;
        hFunctions.resetTime = @resetTime;
        hFunctions.changeMerge = @changeMerge;
        hFunctions.autoscaleRGB = @autoscaleRGB;
        hFunctions.changeDepthColor = @changeDepthColor;
        hFunctions.toggleRGB = @toggleRGB;
        hFunctions.eventhandlerChanged = @eventhandlerChanged;
        hFunctions.updateList = @updateList;
        hFunctions.initializeOverlays = @initializeOverlays;
        hFunctions.enableTracking = @enableTracking;
%         hFunctions.changeSizeWindow = @changeSizeWindow;
        hFunctions.scrollByWheel = @scrollByWheel;
        hFunctions.playICEGateway = @playICEGateway;
        hFunctions.updateDisplayStatus = @updateDisplayStatus;
        hFunctions.updateVariablesFromExternalFunction = @updateVariablesFromExternalFunction;
        hFunctions.keyPressed = @keyPressed;
        hFunctions.mouseMoved = @mouseMoved;
        hFunctions.selectMenu = @selectMenu;
        hFunctions.GUI2menu = @GUI2menu;
        
        
%         hFunctions.layerChanged = @layerChanged;
%         hFunctions.changeLayer = @changeLayer;
%         hFunctions.toggleMenuCheckBox = @toggleMenuCheckBox;
        hFunctions.toggleControlPanel = @toggleControlPanel;
        hFunctions.closeControlPanel = @closeControlPanel;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Gateway Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Export movie
    function makeMovieGateway(~, ~)
        makeMovie(dimT, dimZ, hFunctions.displayImage, sH.axisImage);
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Register images
    function registerImagesGateway(~, ~)
        registerImagesSubpixel(sH, hFunctions, pathICE,...
            imgRAM, sG.modeImage, sVar, dimX, dimY, dimZ, dimT);
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Time Series
    function scrollableTimeSeriesGateway(~, ~)
%         if issafe('sH.figTS')
%             figure(sH.figTS);
%         else
            switch sG.layers
                case 'max'
                    sH = scrollableTimeSeries(sH, sVar, ND, {neuronsMip}, 1, smallScreen, flgGUI);
                otherwise
                    sH = scrollableTimeSeries(sH, sVar, ND, neurons, dimZ, smallScreen, flgGUI);
            end
%         end
        scrollSliderZ;
        movePlot;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get initial seeds for tracking
    function getSeedsGateway(~, ~)
        
        if sG.check3D % get(sH.check3D, 'Value')
            [neurons, listNeurons] = getSeeds3D(sH, hFunctions, neurons, listNeurons,...
                dimX, dimY, dimZ, dimT, valT, pathICE, ND, sG.modeImage, imgRAM, imgMap, flgGUI);
        else
%             [neurons, listNeurons] = getSeeds(sH, sG, hFunctions, neurons, listNeurons,...
%                 dimZ, dimT, valZ, valT, pathICE, ND, flgGUI);
            [neurons, listNeurons] = getSeeds(sH, sG, hFunctions, neurons, listNeurons,...
                dimZ, dimT, valZ, valT, pathICE, ND, filters, flgGUI, flgWI, handlesWI, tWI, threshSeed);
        end
        
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Track all neurons
    function trackAllGateway(~, ~)
        
        if sG.check3D % get(sH.check3D, 'value')  % If 3D checkbox is checked
            [neurons, listNeurons, sH] = trackAll3D(sH, hFunctions, neurons, listNeurons,...
                dimX, dimY, dimZ, dimT, crop_size_r, crop_size_c, crop_size_z, modeImageTrack,...
                ND, pathICE, imgMap, poolsize, flgGUI);
            
        else % 2D
            [neurons, listNeurons, sH] = trackAll(sH, sG, hFunctions, imgRAM, neurons, listNeurons,...
                dimX, dimY, dimZ, valZ, dimT, dimTP, crop_size_r, crop_size_c, flgGUI, flgWI, handlesWI, tWI, pathFolder);
            
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Track selected neuron
    function trackSelGateway(~, ~)
        
        if sG.check3D % get(sH.check3D, 'value') % If 3D checkbox is checked
            
            neurons = trackSel3D(sH, hFunctions, neurons, dimX, dimY, dimZ, dimT, valZ,...
                ND, crop_size_r, crop_size_c, crop_size_z, pathICE, imgMap, modeImageTrack);
            
        else % 2D
            neurons = trackSel(sH, sG, hFunctions, neurons, dimX, dimY, dimZ, dimT, valZ,...
                ND, crop_size_r, crop_size_c, pathICE, imgMap, modeImageTrack);
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Movie play function
    function playICEGateway(~, ~, command)
        [tScroll, valT, frameSkip, frameWait] = playICE...
            (sH, hFunctions, command, tScroll, valT, dimT, dimZ, frameSkip, frameWait);
        sH.jFig.getAxisComponent.requestFocus;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function [fs, fw] = updateVariablesFromExternalFunction(frameSkipEx, frameWaitEx)
        if exist('frameSkipEx', 'var')
            frameSkip = frameSkipEx;
        end
        if exist('frameWaitEx', 'var')
            frameWait = frameWaitEx;
        end        
        fs = frameSkip;
        fw = frameWait;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% GUI Components
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Nested Functions for creating GUI components
    function createGUI()
        
        % Get a path of this m-file
        [pathM, ~, ~] = fileparts( mfilename('fullpath') );
        sH = loadGUI([pathM, '\displayICE2.fig'], sH);

        % Get java object of the figure
        warning('off','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');
        sH.jFig = get(sH.fig, 'JavaFrame');
        %         set(sH.fig, 'Position', [150 67 1129 1200]);
        %         get(0, 'MonitorPositions') % This should give the current screen resolution
        %         get(0, 'ScreenSize')       % This MIGHT give the original resolution in which MATLAB was started. If
        %         that's the case, then GUI layout will be messed up. A code may be written to compensate this bug by
        %         using these commands.
        
        pos = get(sH.fig, 'Position');
        [~, hostname] = system('hostname');
        hostname = strtrim(hostname);
        switch hostname
            case 'WS'
                set(sH.fig, 'Position', [1200 200 pos(3) pos(4)]);
            case 'GTX670'
                set(sH.fig, 'Position', [64 100 pos(3) pos(4)]);
            otherwise
%                 set(sH.fig, 'Position', [0.04 0.01 1 1]);
        end
        
        [sH, sG] = createMenu(sH, sG, hFunctions, paths);

        sH = procesGUIComponents(sH);

        set(sH.fig, 'Visible', 'on');
        set(sH.fig, 'Renderer', 'zbuffer');
        
        sH = progressBar(flgGUI, sH, 'instantiate');
        
        % Adjust dimensions of Java components
%         hand=findjobj;
        pause(0.1);
        jRootPane = getRootPanel(sH.fig);
        DTRootPane = jRootPane.getComponent(0);
        jMenuBar = DTRootPane.getMenuBar;
        jMenuBar.setPreferredSize( java.awt.Dimension(325, 22) );
        
        jLayeredPane = DTRootPane.getComponent(1);
        jPanel = jLayeredPane.getComponent(1);
        MJPanel = jPanel.getComponent(1);
        MJPanel.setPreferredSize( java.awt.Dimension(850, 18) );
    end
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     function toggleBehaviorPanel(~, ~)
%         if sG.showBehaviorPanel
%             
%             sG.showBehaviorPanel = false;
%         else
%             
%             sG.showBehaviorPanel = true;
%         end
%     end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function toggleControlPanel(~, ~)
        if sG.showControlPanel
            closeControlPanel;
            set(sH.buttonMore, 'String', 'More >>');
            sG.showControlPanel = false;
        else
            posMain = get(sH.fig, 'Position');
            xCtrl = posMain(1) + posMain(3) + 0.0085;
            yCtrl = posMain(2) + 0.018;
            [pathM, ~, ~] = fileparts( mfilename('fullpath') );
            sHCtrl = loadGUI([pathM, '\displayIceCtrl.fig'], sHCtrl);
            posCtrl = get(sHCtrl.figCtrl, 'Position');
            set(sHCtrl.figCtrl, 'Position', [xCtrl yCtrl posCtrl(3) posCtrl(4)]);
            
            sHCtrl = procesGUIComponents(sHCtrl);
            associateCallbacksForCtrlPanel;
            
            % Initial values
            switch sG.modeImage
                case 'map'
                    setValuesControlPanel('selectModeImage', 1);
                case 'RAM'
                    setValuesControlPanel('selectModeImage', 2);
                case 'uint16'
                    setValuesControlPanel('selectModeImage', 3);
            end
            setValuesControlPanel('toggleSegm', sG.showRegions);
            setValuesControlPanel('toggleLabel', sG.showLabels);
            setValuesControlPanel('toggleGVF', sG.showGVF);
            
            
            set(sH.buttonMore, 'String', 'Less <<');
            sG.showControlPanel = true;
            figure(sH.fig);
            sH.jFig.getAxisComponent.requestFocus;
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function closeControlPanel(~, ~)
        free(sHCtrl.figCtrl);
        set(sH.buttonMore, 'String', 'More >>');
        sG.showControlPanel = false;
        figure(sH.fig);
        sH.jFig.getAxisComponent.requestFocus;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function handles = procesGUIComponents(handles)
        
        % Font type
        fName = 'Arial';
        if smallScreen
            fSize = 7;
        else
            fSize = 8;
        end
        
        clr = [.85 .85 .85];
        
        cFields = fieldnames(handles);
        sizeH = numel(cFields);
        for sh = 1:sizeH
            if numel( handles.(cFields{sh}) ) == 1 && ishandle( handles.(cFields{sh}) ) && ~isjava( handles.(cFields{sh}) )
                type = get(handles.(cFields{sh}), 'Type');
                switch type
                    case 'figure'
                        set(handles.(cFields{sh}), 'Color', clr );
                        set(handles.(cFields{sh}), 'Resize', 'off' );
                    case 'uipanel'
                        set(handles.(cFields{sh}), 'BackgroundColor', clr);
                        set(handles.(cFields{sh}), 'FontName', fName);
                        set(handles.(cFields{sh}), 'FontSize', fSize);
                    case 'uicontrol'
                        style = get(handles.(cFields{sh}), 'Style');
                        switch style
                            case {'checkbox', 'radiobutton', 'text'}
                                set(handles.(cFields{sh}), 'BackgroundColor', clr);
                        end
                        set(handles.(cFields{sh}), 'FontName', fName );
                        set(handles.(cFields{sh}), 'FontSize', fSize );
                    case 'axes'
                        set(handles.(cFields{sh}), 'FontName', fName);
                        set(handles.(cFields{sh}), 'FontSize', fSize);
                end
%                 set(handles.(cFields{sh}), 'Unit', 'normalized' );
            end
        end 
        
    end
        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function associateCallbacks
        
%         jCont = sH.jFig.getFigurePanelContainer;
%         hCont = handle(jCont, 'CallbackProperties'); % Wrap the j-object with M-handle to avoid memory leak
%         set(hCont, 'MouseWheelMovedCallback', hFunctions.scrollByWheel);
        
        % Event listener for the list box. Required for callbacks from another fig
        addlistener(sH.listN, 'Value', 'PostSet', hFunctions.selectList);

        % Callback functions for MATLAB uicontrols
        set(sH.fig, 'CloseRequestFcn', hFunctions.quitFile);
%                          'WindowButtonMotionFcn', hFunctions.mouseMoved);
%         set(sH.buttonSlower, 'Unit', 'normalized', 'Position', positions.buttonSlower);
%         set(sH.jButtonSlower, 'MouseReleasedCallback', {hFunctions.playICEGateway, 'slower'});
        set(sH.buttonGroupLayers, 'SelectionChangeFcn', hFunctions.GUI2menu);
        set(sH.checkFlipVertical, 'Callback', hFunctions.GUI2menu);
        set(sH.checkFlipHorizontal, 'Callback', hFunctions.GUI2menu);
        set(sH.checkR, 'Callback', {hFunctions.toggleRGB, 'R'});
        set(sH.checkG, 'Callback', {hFunctions.toggleRGB, 'G'});
        set(sH.checkB, 'Callback', {hFunctions.toggleRGB, 'B'});
        set(sH.buttonAutoscale, 'Callback', hFunctions.autoscaleRGB);
        set(sH.menuDepthColorR, 'Callback', {hFunctions.changeDepthColor, 1});
        set(sH.menuDepthColorG, 'Callback', {hFunctions.changeDepthColor, 2});
        set(sH.menuDepthColorB, 'Callback', {hFunctions.changeDepthColor, 3});
        set(sH.buttonMore, 'Callback', hFunctions.toggleControlPanel);
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function associateCallbacksForCtrlPanel()
        set(sHCtrl.figCtrl, 'CloseRequestFcn', hFunctions.closeControlPanel);
        set(sHCtrl.buttonAdd, 'Callback', hFunctions.addNeuron);
        set(sHCtrl.buttonDel, 'Callback', hFunctions.delNeuron);
        set(sHCtrl.buttonRename, 'Callback', hFunctions.renameNeuron);
        set(sHCtrl.toggleSegm, 'Callback', hFunctions.GUI2menu);
        set(sHCtrl.toggleLabel, 'Callback', hFunctions.GUI2menu);
        set(sHCtrl.toggleGVF, 'Callback', hFunctions.GUI2menu);
        set(sHCtrl.buttonMerge, 'Callback', hFunctions.mergeNeuron);
        set(sHCtrl.buttonOpen, 'Callback', hFunctions.openFile);
        set(sHCtrl.selectModeImage, 'Callback', hFunctions.GUI2menu);
        set(sHCtrl.buttonRegister, 'Callback', hFunctions.registerImagesGateway);
        set(sHCtrl.buttonQuit, 'Callback', hFunctions.quitFile);
        set(sHCtrl.buttonShow, 'Callback', hFunctions.showTimeSeries);
        set(sHCtrl.buttonSave, 'Callback', hFunctions.saveTimeSeries);
        set(sHCtrl.buttonSaveAnalysis, 'Callback', hFunctions.saveLabels);
        set(sHCtrl.buttonLoadAnalysis, 'Callback', hFunctions.loadLabels);
        set(sHCtrl.buttonMovie, 'Callback', hFunctions.makeMovieGateway);
        set(sHCtrl.buttonTemperatures, 'Callback', hFunctions.showTemperatures);
        set(sHCtrl.buttonROI, 'Callback', hFunctions.createROI);
        set(sHCtrl.buttonMeasure, 'Callback', hFunctions.measureIntensity);
        set(sHCtrl.buttonAddToNeurons, 'Callback', hFunctions.addAsNeuron);
%         set(sHCtrl.menuSizeWindow, 'Callback', hFunctions.changeSizeWindow);
        set(sHCtrl.buttonSeeds, 'Callback', hFunctions.getSeedsGateway);
        set(sHCtrl.buttonTrackAll, 'Callback', hFunctions.trackAllGateway);
        set(sHCtrl.buttonTrackSel, 'Callback', hFunctions.trackSelGateway);        
        
    end


end

