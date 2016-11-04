function [sH, sG] = createMenu(sH, sG, hFunctions, paths)

% [path, ~, ~] = fileparts(which(mfilename));  % Get the path of the m-file executing
% pathIconChecked = [path, '\icons\checked.png'];
% pathIconUnchecked = [path, '\icons\unchecked.png'];
% pathIconEmpty = [path, '\icons\empty.png'];

% jicon = javax.swing.ImageIcon(pathIconPlay);
% jButtonPlay = javax.swing.JToggleButton(jicon);
% [handles.jButtonPlay, handles.buttonPlay] = javacomponent(jButtonPlay, [], handles.panelView);
% set(handles.buttonPlay, 'Unit', 'normalized', 'Position', positions.buttonPlay);
% set(handles.jButtonPlay, 'MouseReleasedCallback', {hFunctions.playICEGateway, 'play'});


labels = char(...
    '&File', ...                 1
    '>&Open ICE', ...            1.1
    '>-------', ...              1.2
    '>&Image Mode', ...          1.3
    '>>&Disk', ...               1.3.1
    '>>&RAM', ...                1.3.2
    '>>&Mapped', ...             1.3.3
    '>&Save Labels', ...         1.4
    '>&Load Labels', ...         1.5
    '>Save &Time-series', ...    1.6
    '>-------', ...              1.7
    '>&Quit', ...                1.8
    '&Analysis', ...             2
    '>&Show Time-series', ...    2.1
    '>Show &Heatmap', ...        2.2
    '>-------', ...              2.3
    '>&Register Images', ...     2.4
    '>Use &CUDA', ...            2.5
    '>-------', ...              2.6
    '>&Temperatures', ...        2.7
    '>-------', ...              2.8
    '>RO&I', ...                 2.9
    '>S&hape', ...               2.10
    '>>&Ellipse', ...            2.10.1
    '>>&Rectangle', ...          2.10.2
    '>&Measure', ...             2.11
    '>&Add as Neuron', ...       2.12
    '>-------', ...              2.13
    '>&Export Movie', ...        2.14
    '&Tracking',...              3
    '>&Get Seeds', ...           3.1
    '>For All &Z', ...           3.2
    '>-------', ...              3.3
    '>Track &All', ...           3.4
    '>Track in 3&D', ...         3.5
    '>&Register before Track',...3.6
    '>-------', ...              3.7
    '>Track &Selected', ...      3.8
    '&View', ...                 4
    '>&Autoscale', ...           4.1
    '>-------', ...              4.2
    '>Flip &Vertically',...      4.3
    '>Flip &Horizontally',...    4.4
    '>-------', ...              4.5
    '>Show &Regions',...         4.6
    '>Show &Labels',...          4.7
    '>Show &GVF',...             4.8
    '>-------', ...              4.9
    '>Toggle &Overlays', ...     4.10
    '&Layers', ...               5
    '>&Red',...                  5.1
    '>&Green',...                5.2
    '>RG&B',...                  5.3
    '>&Max',...                  5.4
    '&Neurons',...               6
    '>&Add Neuron',...           6.1
    '>&Delete Neuron',...        6.2
    '>&Rename Neuron',...        6.3
    '&Behavior',...              7
    '>Pointer Scroll', ...       7.1
    '>Label Behaviors', ...      7.2
    '>Add Worm', ...             7.3
    '>Delete Worm', ...          7.4
    '>Show Behaviors', ...       7.5
    '>Add Behaviors', ...        7.6
    '>Mark X',...                7.7
    '>Demark X',...              7.8
    '>Previous Worm',...         7.9
    '>Next Worm'...              7.10
    );

calls = repmat({{hFunctions.selectMenu}}, size(labels,1), 1);
calls( ~(labels(:, 1) == '>') ) = {''}; % Empty cells for top layer menu items
calls(  (labels(:, 2) == '-') ) = {''}; % Empty cells for separators
calls(4, 1) = {''}; % Empty cells that have sub-menus
calls(23, 1) = {''}; % Empty cells that have sub-menus

makemenu2(sH.fig, labels, calls); % Create menu

jFrame = get(handle(sH.fig),'JavaFrame');
try
    % R2014a and earlier
    jM = jFrame.fHG1Client.getMenuBar;
catch
    % R2014b and later
    jM = jFrame.fHG2Client.getMenuBar;
%     jM = jFrame.fFigureClient.getMenuBar;
end

pause(0.1);

% Get Java components of the top menus, and open them before they are modified
for m = 1:jM.getComponentCount
    jMTop{m} = jM.getComponent(m-1); %#ok<AGROW>
    pause(0.01);
    jMTop{m}.doClick;
end

% Close open menus
javax.swing.MenuSelectionManager.defaultManager().clearSelectedPath();

pause(0.05);

% Get Java components for menu items
for m = 1:jM.getComponentCount
    for c = 1:jMTop{m}.getMenuComponentCount
        jMItems{c, m} = jMTop{m}.getMenuComponent(c-1); %#ok<AGROW>
    end
end

% Get Java components for sub-menu items
for c = 1:jMItems{3, 1}.getMenuComponentCount % File -> Image Mode
    jMItemsSub{c, 1} = jMItems{3, 1}.getMenuComponent(c-1); %#ok<AGROW>
end
for c = 1:jMItems{10, 2}.getMenuComponentCount % Analysis -> Shape
    jMItemsSub{c, 2} = jMItems{10, 2}.getMenuComponent(c-1);
end

% Set accelerator keys for menu items:

% keysMenu = {...
%     1, 4,  'S';...  % Save labels
%     1, 8,  'Q';...  % Quit
%     2, 1,  'T';...  % Time-series
%     4, 1,  'A';...  % Autoscale
%     4, 3,  'W';...  % Flip vertical
%     4, 4,  'D';...  % Flip horizontal
%     4, 10, 'X';...  % Toggle Overlays
%     6, 3,  'R';...  % Rename neuron
%     7, 1,  'E';...  % Toggles Pointer scroll mode
%     7, 2,  'B';...  % Label Behaviors
%     7, 3,  'V';...  % Add Worm
%     7, 5,  'G'...   % Show Behaviors
%     };
% 
% keysMenuSub = {...
%     1, 1,  'K';...  % Image mode disk
%     1, 2,  'M'...   % Image mode RAM
%     };

assignKeyStrokes(jMItems,    'main', 'play');
assignKeyStrokes(jMItemsSub, 'sub',  'play');


% jMItems{4, 1}.setAccelerator( javax.swing.KeyStroke.getKeyStroke('S') ); % Save labels
% jMItems{8, 1}.setAccelerator( javax.swing.KeyStroke.getKeyStroke('Q') ); % Quit
% jMItems{1, 2}.setAccelerator( javax.swing.KeyStroke.getKeyStroke('T') ); % Time-series
% jMItems{1, 4}.setAccelerator( javax.swing.KeyStroke.getKeyStroke('A') ); % Autoscal
% jMItems{3, 4}.setAccelerator( javax.swing.KeyStroke.getKeyStroke('W') ); % Flip vertical
% jMItems{4, 4}.setAccelerator( javax.swing.KeyStroke.getKeyStroke('D') ); % Flip horizontal
% jMItems{10,4}.setAccelerator( javax.swing.KeyStroke.getKeyStroke('X') ); % Toggle Overlays
% jMItems{3, 6}.setAccelerator( javax.swing.KeyStroke.getKeyStroke('R') ); % Rename neuron
% jMItems{1, 7}.setAccelerator( javax.swing.KeyStroke.getKeyStroke('E') ); % Toggles Pointer scroll mode
% jMItems{2, 7}.setAccelerator( javax.swing.KeyStroke.getKeyStroke('released B') ); % Label Behaviors
% jMItems{3, 7}.setAccelerator( javax.swing.KeyStroke.getKeyStroke('V') ); % Add Worm
% jMItems{5, 7}.setAccelerator( javax.swing.KeyStroke.getKeyStroke('G') ); % Show Behaviors
% 
% jMItemsSub{1, 1}.setAccelerator( javax.swing.KeyStroke.getKeyStroke('K') ); % Image mode disk
% jMItemsSub{2, 1}.setAccelerator( javax.swing.KeyStroke.getKeyStroke('M') ); % Image mode RAM

sH.jMenu = jM;
sH.jMenuTop = jMTop;
sH.jMenuItems = jMItems;
sH.jMenuItemsSub = jMItemsSub;

% Set icons and initial GUI states
updateMenuIcon(5, 2, sH.jMenuItems, 'add', paths, 'iconChecked');      sG.useCUDA = true;
updateMenuIcon(9, 2, sH.jMenuItems, 'add', paths, 'iconUnchecked');    sG.showROI = false;
updateMenuIcon(10,2, sH.jMenuItems, 'add', paths, 'iconEmpty');        % Shape
updateMenuIcon(2, 3, sH.jMenuItems, 'add', paths, 'iconChecked');      sG.forAllZ = true;
updateMenuIcon(5, 3, sH.jMenuItems, 'add', paths, 'iconUnchecked');    sG.track3D = false;
updateMenuIcon(6, 3, sH.jMenuItems, 'add', paths, 'iconUnchecked');    sG.registerBeforeTrack = false;
updateMenuIcon(3, 4, sH.jMenuItems, 'add', paths, 'iconUnchecked');    sG.flipVertical = false;
updateMenuIcon(4, 4, sH.jMenuItems, 'add', paths, 'iconUnchecked');    sG.flipHorizontal = false;
updateMenuIcon(6, 4, sH.jMenuItems, 'add', paths, 'iconUnchecked');    sG.showRegions = false;
updateMenuIcon(7, 4, sH.jMenuItems, 'add', paths, 'iconChecked');      sG.showLabels = true;
updateMenuIcon(8, 4, sH.jMenuItems, 'add', paths, 'iconUnchecked');    sG.showGVF = false;
updateMenuIcon(1, 5, sH.jMenuItems, 'add', paths, 'iconChecked');      % Red
updateMenuIcon(2, 5, sH.jMenuItems, 'add', paths, 'iconUnchecked');    % Green
updateMenuIcon(3, 5, sH.jMenuItems, 'add', paths, 'iconUnchecked');    % RGB
updateMenuIcon(4, 5, sH.jMenuItems, 'add', paths, 'iconUnchecked');    % Max
updateMenuIcon(1, 7, sH.jMenuItems, 'add', paths, 'iconUnchecked');    sG.scrollPointer = false;
updateMenuIcon(2, 7, sH.jMenuItems, 'add', paths, 'iconUnchecked');    sG.labelBehaviors = false;
updateMenuIcon(5, 7, sH.jMenuItems, 'add', paths, 'iconUnchecked');    sG.showBehaviors = false;

updateMenuIcon(1, 1, sH.jMenuItemsSub, 'add', paths, 'iconChecked');   sG.modeImage = 'uint16';
updateMenuIcon(2, 1, sH.jMenuItemsSub, 'add', paths, 'iconUnchecked'); % RAM
updateMenuIcon(3, 1, sH.jMenuItemsSub, 'add', paths, 'iconUnchecked'); % map
updateMenuIcon(1, 2, sH.jMenuItemsSub, 'add', paths, 'iconChecked');   % Ellipse
updateMenuIcon(2, 2, sH.jMenuItemsSub, 'add', paths, 'iconUnchecked'); % Rectangle

end

