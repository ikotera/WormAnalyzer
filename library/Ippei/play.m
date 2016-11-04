function play(argin)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                 play.m                                  %
%                               Ver. 1.03                                 %
%                      Dec. 5, 2011 by Ippei Kotera                       %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% The function plays dat files created by Leo's tracker. Slider uicontrol
% has been modified with Java components to display frames "real-time". The
% figure also calls a nested function for mouse wheel scrolling of images.
% The function requires following external functions:
%       
%       openDatFast.m
%       findjobj.m
%
% This function is intended to be called directly by double-clicking a dat
% file. To do this, merge the following registry information to your
% system, by saving the text (without % marks) as .reg file and executing
% it. You may want to change the application path according to your MATLAB
% installation path.
%
%
% Windows Registry Editor Version 5.00
% 
% [HKEY_CLASSES_ROOT\dat_auto_file]
% @=""
% 
% [HKEY_CLASSES_ROOT\dat_auto_file\shell]
% @="Open"
% 
% [HKEY_CLASSES_ROOT\dat_auto_file\shell\Open]
% 
% [HKEY_CLASSES_ROOT\dat_auto_file\shell\Open\command]
% @="\"C:\\Program Files\\MATLAB\\R2011b\\bin\\win64\\matlab.exe\""
% 
% [HKEY_CLASSES_ROOT\dat_auto_file\shell\Open\ddeexec]
% @="play('%1');"
% 
% [HKEY_CLASSES_ROOT\dat_auto_file\shell\Open\ddeexec\application]
% @="ShellVerbs.MATLAB"
% 
% [HKEY_CLASSES_ROOT\dat_auto_file\shell\Open\ddeexec\topic]
% @="system"
%
% 
% Version History:
% 1.00; Dec. 5, 2011: Initial release.
% 
% 1.01; Feb. 17, 2012: In stead of calling imagesc each time, only the
% CData is changed at each frame. Together with 'EraseMode' set to 'none',
% it plays image stack at much faster rate. OpenGL has strange problem with
% EraseMode.
% 
% 1.02; Oct. 16, 2012: The function now supports both dat file path and 3D
% matrix as input argument.
%
% 1.03; Nov. 28, 2012: Added support for ice files.

%% Check Input Argument

if ischar(argin)
    pathDat = argin;
    clear argin;
    [~, ~, ext] = fileparts(pathDat);
    
    switch ext
        case '.dat'
            modeData = 'dat';
        case '.ice'
            modeData = 'ice';
    end
elseif ndims(argin) >= 2 && ndims(argin) <= 3
    nameArgin = inputname(1);
    dataMatrix = argin;
    clear argin;
    modeData = 'matrix';
else
    disp('Input argument needs to be either dat file path or matrix data');
    return
end

%% Initialization

% opengl('OpenGLEraseModeBug', 0)

% Display maginification
mag = 0.5;

% Figure positions
marginX = 40;
marginY = 80;

% Initial frame number
currentFrame = 1;

switch modeData
    
    case 'ice'
        
        fid = fopen(pathDat, 'r');
        fseek(fid, 0, 'eof');
        lastByte = ftell(fid);
        fseek(fid, 0, 'bof');
        xDimStack = fread(fid, 1, 'double'); % 8 bytes
        yDimStack = fread(fid, 1, 'double'); % 8 bytes
        
        % Size of each frame in bytes
        byteSizeFrame = xDimStack * yDimStack * 2;
        %Each uint16 pixel is 2 bytes long.
        
        % The size of the ice file header is 2048 + 2048 = 4096 bytes
        byteSizeImageStack = lastByte - 4096;
        
        % Number of frames
        numFrames = round(byteSizeImageStack / byteSizeFrame);
        
        % Open the Dat file for initial parameters
        img = openICE(1, 1, pathDat);
    
    case 'dat'
        
        % Open the dat file for header information
        fid = fopen(pathDat, 'r');
        fseek(fid, 0, 'eof');
        lastByte = ftell(fid);
        fseek(fid, 0, 'bof');
        xDimStack = fread(fid, 1, 'uint32'); % 4 bytes
        yDimStack = fread(fid, 1, 'uint32'); % 4 bytes
        
        % Size of each frame in bytes
        byteSizeFrame = xDimStack * yDimStack * 2 + 9 + 16;
        %Each 16bit pixel is 2 bytes long. Timestamp and motor status
        %together are 9 bytes long. As of Feb 10th, 2010.
        %Added June 28th, 2010. XY coordinates are two int64, 8 + 8 = 16 bytes.
        
        % The size of the dat file header is 8*6+4*2+2*4+1*6 = 70 bytes
        byteSizeImageStack = lastByte - 70;
        
        % Number of frames
        numFrames = round(byteSizeImageStack / byteSizeFrame);
        
        % Open the Dat file for initial parameters
        img = openDatFast(1, 1, pathDat);
        
    case 'matrix'
        
        img = dataMatrix(:, :, 1);
        numFrames = size(dataMatrix, 3);
end


[yDim, xDim] =size(img(:, :));
yDim = yDim * mag;
xDim = xDim * mag;

% Find the max intensity of the first image
imgTemp = img(:);
imgTemp(isnan(imgTemp)) = 0; % Get rid of NaNs
maxIntensity = max(imgTemp);

% Find the max intensity of the first image
imgTemp = img(:);
imgTemp(isnan(imgTemp)) = inf; % Get rid of NaNs
minIntensity = min(imgTemp);

if ~ maxIntensity > minIntensity || ~isfinite(minIntensity)
    maxIntensity = 2^16;
    minIntensity = 1;
end

%% Create uicontrol Elements 
% Calculate postions
updatePos;

% Create a figure with mouse wheel callback
hFig = figure('WindowScrollWheelFcn', @scrollByWheel);
set(hFig,...
    'Units', 'Pixel',...
    'Toolbar', 'figure',...
    'Position', posFig,...
    'Renderer', 'Painters');


% Create axis for image display
hAxis = axes('Parent', hFig, 'YDir', 'reverse', 'Units', 'pixels',...
    'Position', posAxis, 'Layer','top', 'Visible', 'off',...
    'XLim',[0 xDim],'YLim',[0 yDim]);

% Display the file path or matrix info
switch modeData 
    case {'dat', 'ice'}
        tx = pathDat;
        [~, nameFig, ~] = fileparts(pathDat);
    case 'matrix'
        s = whos('dataMatrix');
        tx = [nameArgin, ', ', mat2str(s.size), ', ',...
            num2str(s.bytes), ', ', s.class];
        nameFig = nameArgin;
end

% Put window title
set(hFig,'name', nameFig, 'numbertitle', 'off');

hTextFilePath = uicontrol(hFig, 'Style', 'text',...
    'String', tx,...
    'BackgroundColor', get(hFig, 'Color'),...
    'HorizontalAlignment', 'Left',...
    'FontSize', 10,...
    'Position', posTextFilePath);

% Create a slider control
hSlider = uicontrol(hFig, 'Style', 'slider',...
    'Position', posSlider,...
'SliderStep', [0.001 .01]);

% Create a text edit for magnification control
hEditMag = uicontrol(hFig,'Style','edit',...
    'String', mag,...
    'Position', posEditMag,...
    'Callback', @changeMag);
hTextMag = uicontrol(hFig, 'Style', 'text',...
    'String', 'Magnification',...
    'BackgroundColor', get(hFig, 'Color'),...
    'Position', posTextMag);

% Create a text edit for max intensity control
hEditMax = uicontrol(hFig,'Style','edit',...
    'String', maxIntensity,...
    'Position', posEditMax,...
    'Callback', @changeMax);
hTextMax = uicontrol(hFig, 'Style', 'text',...
    'String', 'Max Intensity',...
    'BackgroundColor', get(hFig, 'Color'),...
    'Position', posTextMax);

% Create a text edit for min intensity control
hEditMin = uicontrol(hFig,'Style','edit',...
    'String', minIntensity,...
    'Position', posEditMin,...
    'Callback', @changeMin);
hTextMin = uicontrol(hFig, 'Style', 'text',...
    'String', 'Min Intensity',...
    'BackgroundColor', get(hFig, 'Color'),...
    'Position', posTextMin);

% Find Java components of the slider (Requires external findjobj.m)
jScrollBar = findjobj(hSlider);
set(jScrollBar, 'AdjustmentValueChangedCallback', @scrollBySlider);
set(jScrollBar,...
    'maximum', (numFrames + 10) * 1000,...
    'minimum', 1 * 1000,...
    'unitIncrement', 1000,...
    'blockIncrement', 10000);

% Display the first image
% Open an image from dat file

switch modeData
    
    case 'ice'
        img = openICE(currentFrame, 1, pathDat);
    
    case 'dat'
        img = openDatFast(currentFrame, 1, pathDat);
        
    case 'matrix'
        img = dataMatrix(:, :, 1);
        
end

hI = imagesc(img(:, :), [minIntensity maxIntensity]);
set(hI, 'EraseMode', 'none');
set(hAxis, 'XTick', [], 'YTick', []);
displayAll;


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
        
        % Display the current image
        displayAll;
        
    end

% Nested Function for Slider
    function scrollBySlider(~,~)
        
        % Get the slider value
        val1 = get(jScrollBar,'Value');
        currentFrame = round(val1 / 1000);
        
        % Make sure frame number stays within the range
        if(currentFrame > numFrames)
            currentFrame = numFrames;
        end
        
        % Display the current image
        displayAll;
        
    end

% Nested Funciton for Data Display
    function displayAll
        
        switch modeData
            case 'ice'
                img = openICE(currentFrame, 1, pathDat);
            case 'dat'
                % Open an image from dat file
                img = openDatFast(currentFrame, 1, pathDat);
            case 'matrix'
                img = dataMatrix(:, :, currentFrame);
        end
        
        % Get rid of NaN
        imgTemp = img(:,:);
        imgTemp(isnan(imgTemp)) = inf;
        
        % Display an image
        set(hI, 'CData', img);
        set(hAxis, 'CLim', [minIntensity maxIntensity])
        
        % Dispays title
        title([num2str(xDim / mag) ' x ' num2str(yDim / mag)...
            ', ' num2str(currentFrame,'%05.0f') '/'...
            num2str(numFrames,'%05.0f')....
            ', Max=' num2str(max(max(img)),'%05.0f')...
            ', Min=' num2str(min(min(imgTemp)),'%05.0f')]);
    end

% Nested Function for Mag Edit
    function changeMag(hObj, ~)
        
        % Get the edit value
        mag = str2double(get(hObj,'String'));
        
        % Realculate image information
        [yDim, xDim] =size(img(:, :));
        yDim = yDim * mag;
        xDim = xDim * mag;
        updatePos;
        
        % Update all positions of uicontrol elements
        set(hFig, 'Position', posFig);
        set(hAxis, 'Position', posAxis);
        set(hTextFilePath, 'Position', posTextFilePath);        
        set(hSlider, 'Position', posSlider);
        set(hEditMag, 'Position', posEditMag);
        set(hTextMag, 'Position', posTextMag);
        set(hEditMax, 'Position', posEditMax);
        set(hTextMax, 'Position', posTextMax);
        set(hEditMin, 'Position', posEditMin);
        set(hTextMin, 'Position', posTextMin);
        
    end

% Nested Function for Max Edit
    function changeMax(hObj, ~)
        
        % Get the edit value
        maxIntensity = str2double(get(hObj,'String'));
        displayAll;
                
    end

% Nested Function for Min Edit
    function changeMin(hObj, ~)
        
        % Get the edit value
        minIntensity = str2double(get(hObj,'String'));
        displayAll;
                
    end


%% Position Data for uicontrol Elements
% Nested Function for Position Data Update
    function updatePos
        
        % Positions of uicontrol elements
        posFig = [200 200 xDim + 160 yDim + 140];
        posAxis = [marginX marginY xDim yDim];
        posTextFilePath = [marginX marginY + yDim + 30 500 25];
        posSlider = [marginX 20 xDim 30];
        posEditMag = [marginX + xDim + 20 marginY + yDim - 60 80 20];
        posTextMag = [marginX + xDim + 20 marginY + yDim - 40 80 15];
        posEditMax = [marginX + xDim + 20 marginY + yDim - 100 80 20];
        posTextMax = [marginX + xDim + 20 marginY + yDim - 80 80 15];
        posEditMin = [marginX + xDim + 20 marginY + yDim - 140 80 20];
        posTextMin = [marginX + xDim + 20 marginY + yDim - 120 80 15];
        
    end

end


