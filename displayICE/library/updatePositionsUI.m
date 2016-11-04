function updatePositionsUI(handles, positions, smallScreen)

if smallScreen
    fSize = 7;
else
    fSize = 9;
end

 nf = fieldnames(positions);
 numPositions = numel(nf);
 
 for ii =  1:numPositions
     n = nf{ii};
     switch n
         case 'sliderRGB'
         otherwise
             set(handles.(n), 'Position', positions.(n));
     end
     switch n
         case {'fig', 'axisImage', 'listN', 'sliderT', 'sliderZ', 'sliderRGB',...
                 'buttonPlay', 'jButtonPlay', 'buttonFaster', 'jButtonFaster',...
                 'buttonSlower', 'jButtonSlower'}
         otherwise
             set(handles.(n), 'FontSize', fSize);
     end
 end