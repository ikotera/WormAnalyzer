function positions = getPositionsUI(smallScreen)

% Get Windows' Taskbar dimension
sizeWin = getSizeWindows;
tbw = sizeWin.screen.width - sizeWin.bounds.width;
tbh = sizeWin.screen.height - sizeWin.bounds.height;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Poistions (Large Size)
if ~smallScreen
    
    %-----------------------------------------------------------------------------------------------
    % Figure
    positions.fig = [10+tbw 10+tbh+200 1184 1270];
    %-----------------------------------------------------------------------------------------------
    % Panels
    wPI = 0.895; % width of image panel
    hSB = 0.017; % height of status bar (20 pixels)
    positions.panelImage = [0 0.1+hSB wPI 0.9-hSB];
    positions.panelControl = [wPI 0.1+hSB 1-wPI 0.9-hSB];
    positions.panelMenu = [0 hSB 0.333 0.1];
    positions.panelTrack = [0.333 hSB 0.333 0.1];
    positions.panelView = [0.666 hSB 0.333 0.1];
    %-----------------------------------------------------------------------------------------------
    % Image axis
    positions.axisImage = [25 50 1024 1024];
    %-----------------------------------------------------------------------------------------------
    % Control Panel - Push buttons
    positions.buttonAdd = [0 0.98 1 0.02];
    positions.buttonDel = [0 0.955 1 0.02];
    positions.buttonRename = [0 0.93 1 0.02];    
    %-----------------------------------------------------------------------------------------------
    % Neuron list
    positions.checkSyncList = [0 0.905 1 0.02]; % Added 140207    
    positions.SelectZ = [0 0.88 1.0 0.02]; % Added 140116
    positions.listN = [0 0.33 1 0.54];
    %-----------------------------------------------------------------------------------------------
    % Control Panel - Check boxes; Added 140130
    positions.checkFlipUD = [0 0.31 1 0.02];
    positions.checkFlipLR = [0 0.29 1 0.02];
    %-----------------------------------------------------------------------------------------------
    % Control Panel - Toggle buttons
    positions.toggleSegm = [0 0.17 1 0.02];
    positions.toggleLabel = [0 0.14 1 0.02];
    positions.toggleGVF = [0 0.11 1 0.02];
    %-----------------------------------------------------------------------------------------------
    % Image Type Group
    positions.optionType = [0 0 1 0.1];
    positions.option1 = [0.1 0.7 0.9 0.2];
    positions.option2 = [0.1 0.5 0.9 0.2];
    positions.option3 = [0.1 0.3 0.9 0.2];
    positions.option4 = [0.1 0.1 0.9 0.2];
    %-----------------------------------------------------------------------------------------------
    % Control panel - Merge neurons
    positions.textA = [0.3 0.215 0.3 0.02];
    positions.buttonMerge = [0 0.24 0.5 0.04];
    positions.selectNeuron1 = [0.5 0.24 0.5 0.04];
    positions.selectNeuron2 = [0.5 0.2 0.5 0.04];
    %-----------------------------------------------------------------------------------------------
    % Menu objects
    positions.buttonOpen =          [0.01 0.8 0.31 0.2];
    positions.selectModeImage =     [0.33 0.8 0.31 0.2];
    positions.buttonRegister =      [0.01 0.55 0.31 0.2];
    positions.checkGPU =            [0.33 0.55 0.6 0.2];
    positions.buttonQuit =          [0.66 0.05 0.31 0.2];
    positions.buttonShow =          [0.01 0.3 0.31 0.2];
    positions.buttonSave =          [0.33 0.3 0.31 0.2];
    positions.buttonSaveAnalysis =  [0.01 0.05 0.31 0.2];
    positions.buttonLoadAnalysis =  [0.33 0.05 0.31 0.2];
    positions.buttonMovie        =  [0.66 0.8 0.31 0.2];
    positions.menuSizeWindow     =  [0.66 0.3 0.31 0.2];
    %-----------------------------------------------------------------------------------------------
    % Tracking Option panel objects
    positions.buttonSeeds    = [0.05 0.8 0.4 0.2];
    positions.buttonTrackAll = [0.05 0.55 0.4 0.2];
    positions.buttonTrackSel = [0.05 0.31 0.4 0.2];
    positions.checkAllZ      = [0.5 0.8 0.4 0.2];
    positions.check3D        = [0.5 0.55 0.4 0.2];
    positions.checkRegister  = [0.5 0.3 0.4 0.2];
    %-----------------------------------------------------------------------------------------------
    % View Option panel objects
    positions.checkR        = [0.01 0.88 0.1 0.15];
    positions.checkG        = [0.34 0.88 0.1 0.15];
    positions.checkB        = [0.67 0.88 0.1 0.15];
    positions.buttonPlay    = [0.94 -0.0052 0.023 0.02];
    positions.buttonFaster  = [0.968 -0.0052 0.023 0.02];
    positions.buttonSlower  = [0.913 -0.0052 0.023 0.02];
    positions.buttonAutoscale = [0.01 0.05 0.2 0.2];
    positions.menuDepthColorR = [0.15 0.95 0.18 0.1];
    positions.menuDepthColorG = [0.48 0.95 0.18 0.1];
    positions.menuDepthColorB = [0.81 0.95 0.18 0.1];
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Poistions (Small Size)
else
%% --------------------------------------------------------------------------------------
    % Figure
    positions.fig = [10+tbw 10+tbh 700 700];
    %-----------------------------------------------------------------------------------------------
    % Panels
    wPI = 0.82; % width of image panel
    hPL = 0.16;   % height of lower panels
    hBC = 0.033;   % height of buttons on control panel
    hSB = 0.026; % height of status bar (20 pixels)
    wBM = 0.32; % width of buttons on menu panel
    wBT = 0.49; % width of buttons on tracking panel
    positions.panelImage = [0 hPL+hSB wPI 1-hPL-hSB];
    positions.panelControl = [wPI 0.1+hSB 1-wPI 0.9-hSB];
    positions.panelMenu = [0 hSB 0.4 hPL];
    positions.panelTrack = [0.4 hSB 0.3 hPL];
    positions.panelView = [0.7 hSB 0.3 hPL];
    %-----------------------------------------------------------------------------------------------
    % Image axis
    positions.axisImage = [25 30 512 512];
    %-----------------------------------------------------------------------------------------------
    % Control Panel - Push buttons
    positions.buttonAdd = [0 0.96 1 hBC];
    positions.buttonDel = [0 0.92 1 hBC];
    positions.buttonRename = [0 0.88 1 hBC];
    %-----------------------------------------------------------------------------------------------
    % Neuron list
    positions.checkSyncList = [0 0.84 1 hBC]; % Added 140207    
    positions.SelectZ = [0 0.8 1.0 hBC]; % Added 140116    
    positions.listN = [0 0.42+2*hBC 1 0.4-3*hBC];
    %-----------------------------------------------------------------------------------------------
    % Control Panel - Check boxes; Added 140130
    positions.checkFlipUD = [0 0.42+hBC 1 hBC];
    positions.checkFlipLR = [0 0.42 1 hBC];
    %-----------------------------------------------------------------------------------------------
    % Control panel - Merge neurons
    positions.buttonMerge = [0 0.38 0.5 hBC];
    positions.textA = [0.3 0.34 0.3 hBC];
    positions.selectNeuron1 = [0.5 0.38 0.5 hBC];
    positions.selectNeuron2 = [0.5 0.34 0.5 hBC];
    %-----------------------------------------------------------------------------------------------
    % Control Panel - Toggle buttons
    positions.toggleSegm = [0 0.30 1 hBC];
    positions.toggleLabel = [0 0.26 1 hBC];
    positions.toggleGVF = [0 0.22 1 hBC];
    %-----------------------------------------------------------------------------------------------
    % Image Type Group
    positions.optionType = [0 0.065 1 0.14];
    positions.option1 = [0.1 0.7 0.9 0.2];
    positions.option2 = [0.1 0.5 0.9 0.2];
    positions.option3 = [0.1 0.3 0.9 0.2];
    positions.option4 = [0.1 0.1 0.9 0.2];
    %-----------------------------------------------------------------------------------------------
    % Menu objects
    positions.buttonOpen =          [0.01 0.8 wBM 0.2];
    positions.selectModeImage =     [0.34 0.8 wBM 0.2];
    positions.buttonRegister =      [0.01 0.55 wBM 0.2];
    positions.checkGPU =            [0.34 0.55 .6 0.2];
    positions.buttonQuit =          [0.67 0.05 wBM 0.2];
    positions.buttonShow =          [0.01 0.3 wBM 0.2];
    positions.buttonSave =          [0.34 0.3 wBM 0.2];
    positions.buttonSaveAnalysis =  [0.01 0.05 wBM 0.2];
    positions.buttonLoadAnalysis =  [0.34 0.05 wBM 0.2];
    positions.buttonMovie        =  [0.67 0.8 wBM 0.2];
    positions.menuSizeWindow     =  [0.67 0.3 wBM 0.2];
    %-----------------------------------------------------------------------------------------------
    % Tracking Option panel objects
    positions.buttonSeeds    = [0.01 0.8 wBT 0.2];
    positions.buttonTrackAll = [0.01 0.55 wBT 0.2];
    positions.buttonTrackSel = [0.01 0.31 wBT 0.2];
    positions.checkAllZ      = [0.51 0.8 wBT 0.2];
    positions.check3D        = [0.51 0.55 wBT 0.2];
    positions.checkRegister  = [0.51 0.3 wBT 0.2];
    %-----------------------------------------------------------------------------------------------
    % View Option panel objects
    positions.checkR        = [0.01 0.88 0.1 0.15];
    positions.checkG        = [0.34 0.88 0.1 0.15];
    positions.checkB        = [0.67 0.88 0.1 0.15];    
    positions.buttonPlay    = [0.70 0.0 0.11 0.4];
    positions.buttonFaster  = [0.85 0.0 0.11 0.4];
    positions.buttonSlower  = [0.55 0.0 0.11 0.4];
    positions.buttonAutoscale = [0.01 0.05 0.3 0.22];
    positions.menuDepthColorR = [0.09 0.92 0.24 0.1];
    positions.menuDepthColorG = [0.42 0.92 0.24 0.1];
    positions.menuDepthColorB = [0.75 0.92 0.24 0.1];
    
end

%% Slider Positions

if ~smallScreen
    positions.sliderT = [0.021 0.017 0.83 0.02];   
    positions.sliderZ = [0 0.016 0.02 0.5];
    wd = .34; ht = .18; xp = .22; sp = .05; yp1 = .811; yp2 = .574; yp3 = .338;
    
    positions.sliderRGB{1}     = [xp yp1 wd ht];
    positions.sliderRGB{2}     = [xp+wd+sp yp1 wd ht];
    positions.sliderRGB{3}     = [xp yp2 wd ht];
    positions.sliderRGB{4}     = [xp+wd+sp yp2 wd ht];
    positions.sliderRGB{5}     = [xp yp3 wd ht];
    positions.sliderRGB{6}     = [xp+wd+sp yp3 wd ht];    
    
    
%     positions.sliderRGB{1}     = [xp yp1 wd ht];
%     positions.sliderRGB{2}     = [xp yp2 wd ht];
%     positions.sliderRGB{3}     = [xp*2+wd yp1 wd ht];
%     positions.sliderRGB{4}     = [xp*2+wd yp2 wd ht];
%     positions.sliderRGB{5}     = [xp*3+wd*2 yp1 wd ht];
%     positions.sliderRGB{6}     = [xp*3+wd*2 yp2 wd ht];
else
    positions.sliderT = [0.07 0.01 0.9 0.032];
    positions.sliderZ = [0.004 0.05 0.025 0.4];
    wd = .32; ht = .2; xp = .01; yp1 = .63; yp2 = .41;
    positions.sliderRGB{1}     = [xp yp1 wd ht];
    positions.sliderRGB{2}     = [xp yp2 wd ht];
    positions.sliderRGB{3}     = [xp*2+wd yp1 wd ht];
    positions.sliderRGB{4}     = [xp*2+wd yp2 wd ht];
    positions.sliderRGB{5}     = [xp*3+wd*2 yp1 wd ht];
    positions.sliderRGB{6}     = [xp*3+wd*2 yp2 wd ht];
end

end