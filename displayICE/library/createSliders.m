function hdl = createSliders(hdl, hFun, dimTP, dimZ, RGB, smallScreen, depthColor)



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Slider creating functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% if ~smallScreen
%     positions.sliderT = [0.07 0.01 0.9 0.02];
%     sizeKnobT = 40;
%
%     positions.sliderZ = [0 0.05 0.02 0.4];
%     sizeKnobZ = 3;
%
%     wd = .32; ht = .25; xp = .01; yp1 = .65; yp2 = .2;
%     positions.sliderRGB{1}     = [xp yp1 wd ht];
%     positions.sliderRGB{2}     = [xp yp2 wd ht];
%     positions.sliderRGB{3}     = [xp*2+wd yp1 wd ht];
%     positions.sliderRGB{4}     = [xp*2+wd yp2 wd ht];
%     positions.sliderRGB{5}     = [xp*3+wd*2 yp1 wd ht];
%     positions.sliderRGB{6}     = [xp*3+wd*2 yp2 wd ht];
%
% else
%     positions.sliderT = [0.07 0.01 0.9 0.032];
sizeKnobT = 40;
%
%     positions.sliderZ = [0.004 0.05 0.025 0.4];
sizeKnobZ = 3;
%
%     wd = .32; ht = .2; xp = .01; yp1 = .65; yp2 = .2;
%     positions.sliderRGB{1}     = [xp yp1 wd ht];
%     positions.sliderRGB{2}     = [xp yp2 wd ht];
%     positions.sliderRGB{3}     = [xp*2+wd yp1 wd ht];
%     positions.sliderRGB{4}     = [xp*2+wd yp2 wd ht];
%     positions.sliderRGB{5}     = [xp*3+wd*2 yp1 wd ht];
%     positions.sliderRGB{6}     = [xp*3+wd*2 yp2 wd ht];
%
% end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
positions = getPositionsUI(smallScreen);

% Create slider control for time
if dimTP > 1 % If more than one time point

    % Delete the slider if it exists
    if issafe('jScrollBarT')
        delete(hdl.jScrollBarT)
    end

    hdl.sliderT = uicontrol('style','slider');
    ss = 1 / (dimTP - 1);
    set(hdl.sliderT, 'Units', 'normalized', 'Position', positions.sliderT,...
        'SliderStep', [ss ss * 10]);
    hdl.sliderTStep = ss;
    try    % R2013b and older
        addlistener(hdl.sliderT,'ContinuousValueChange',@hFun.scrollSliderT);
    catch  % R2014a and newer
        addlistener(hdl.sliderT,'ActionEvent',@hFun.scrollSliderT);
    end

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create slider control for z-level
if dimZ > 1
    
    % Delete the slider if it exists
    if issafe('jScrollBarZ')
        delete(hdl.jScrollBarZ)
    end
    
    % Create a java slider control
    jscrollbarZ = javax.swing.JScrollBar();
    jscrollbarZ.setOrientation(jscrollbarZ.VERTICAL);
    jscrollbarZ.setVisibleAmount(sizeKnobZ);
    % Display the scroll bar
    [hdl.jScrollBarZ, hdl.sliderZ] = javacomponent(jscrollbarZ,...
        positions.sliderZ, hdl.panelImage);
    set(hdl.sliderZ, 'Units', 'normalized', 'Position', positions.sliderZ);
    set(hdl.jScrollBarZ, 'AdjustmentValueChangedCallback', hFun.scrollSliderZ,...
        'maximum', dimZ + sizeKnobZ,...
        'minimum', 1,...
        'unitIncrement', 1,...
        'blockIncrement', 5);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create RGB sliders
if isempty(hdl.jSliderRGB{1})
    % Create sliders for RGB display control ( RL(1), RH(2), GL(3), GH(4), BL(5), BH(6) )
    for is = 1:6
        
        jslider{is} = javax.swing.JSlider; %#ok<AGROW>
        jslider{is}.setOrientation(jslider{is}.VERTICAL);
        [hdl.jSliderRGB{is}, hdl.sliderRGB{is}] =...
            javacomponent(jslider{is}, positions.sliderRGB{is}, hdl.panelView);
        jslider{is}.setPaintTicks(1);
        if is < 3
            jslider{is}.setBackground(java.awt.Color(hex2dec('FFCCCC'))); % red
        elseif is > 2 && is < 5
            jslider{is}.setBackground(java.awt.Color(hex2dec('CCFFCC'))); % green
        elseif is > 4
            jslider{is}.setBackground(java.awt.Color(hex2dec('CCCCFF'))); % blue
        end
        
        set(hdl.sliderRGB{is}, 'Units', 'normalized', 'Position', positions.sliderRGB{is});
        set(hdl.sliderRGB{is}, 'BackgroundColor', 'r');
        set(hdl.jSliderRGB{is}, 'StateChangedCallback', {hFun.changeMerge, is});
        if rem(is, 2) % Odd number index (max RGB sliders)
            set(hdl.jSliderRGB{is}, 'maximum', 2^depthColor( (is+1)/2, 1 ), 'minimum', 0);
        else
            set(hdl.jSliderRGB{is}, 'maximum', 2^depthColor(is/2, 2), 'minimum', 0);
        end
        set(hdl.jSliderRGB{is}, 'Value', RGB( ceil(is / 2), ~rem(is, 2) + 1 ) * 1 );
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Toggle button for movie playback
[path, ~, ~] = fileparts(which(mfilename));  % Get the path of the m-file executing
pathIconPlay = [path, '\icons\play.gif'];
jicon = javax.swing.ImageIcon(pathIconPlay);
jButtonPlay = javax.swing.JToggleButton(jicon);
[hdl.jButtonPlay, hdl.buttonPlay] = javacomponent(jButtonPlay, [], hdl.panelImage);
set(hdl.buttonPlay, 'Unit', 'normalized', 'Position', positions.buttonPlay);
set(hdl.jButtonPlay, 'MouseReleasedCallback', {hFun.playICEGateway, 'play'});

% Toggle button for speeding up the playback
pathIconFaster = [path, '\icons\forward.gif'];
jicon = javax.swing.ImageIcon(pathIconFaster);
jButtonFaster = javax.swing.JButton(jicon);
[hdl.jButtonFaster, hdl.buttonFaster] = javacomponent(jButtonFaster, [], hdl.panelImage);
set(hdl.buttonFaster, 'Unit', 'normalized', 'Position', positions.buttonFaster);
set(hdl.jButtonFaster, 'MouseReleasedCallback', {hFun.playICEGateway, 'faster'});

% Toggle button for slowing down the playback
pathIconSlower = [path, '\icons\backward.gif'];
jicon = javax.swing.ImageIcon(pathIconSlower);
jButtonSlower = javax.swing.JButton(jicon);
[hdl.jButtonSlower, hdl.buttonSlower] = javacomponent(jButtonSlower, [], hdl.panelImage);
set(hdl.buttonSlower, 'Unit', 'normalized', 'Position', positions.buttonSlower);
set(hdl.jButtonSlower, 'MouseReleasedCallback', {hFun.playICEGateway, 'slower'});




