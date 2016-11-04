function hAxis = plotTemperatures(sVar, hAxis)

% Get all the mins and maxes for plotting scale
minT(1, 1) = min(sVar.tempOven(:, 1));
minT(1, 2) = min(sVar.tempOven(:, 2));
maxT(1, 1) = max(sVar.tempOven(:, 1));
maxT(1, 2) = max(sVar.tempOven(:, 2));
minT(2, 1) = min(sVar.tempDaq(:, 1));
minT(2, 2) = min(sVar.tempDaq(:, 2));
maxT(2, 1) = max(sVar.tempDaq(:, 1));
maxT(2, 2) = max(sVar.tempDaq(:, 2));
minT(3, 1) = min(sVar.tempSet(:, 1));
minT(3, 2) = min(sVar.tempSet(:, 2));
maxT(3, 1) = max(sVar.tempSet(:, 1));
maxT(3, 2) = max(sVar.tempSet(:, 2));
minT = min(minT, [], 1);
maxT = max(maxT, [], 1);

hold on
% Create plots for temperature readings
hPlotOven = plot(sVar.tempOven(:, 2), sVar.tempOven(:, 1),...
    'Parent', hAxis, 'Color', 'red');
hPlotDaq = plot(sVar.tempDaq(:, 2), sVar.tempDaq(:, 1),...
    'Parent', hAxis, 'Color', 'blue');
hPlotSet = plot(sVar.tempSet(:, 2), sVar.tempSet(:, 1),...
    'Parent', hAxis, 'Color', 'green');

% To speed up the plotting process
% set(hPlotOven, 'EraseMode', 'none');
% set(hPlotDaq, 'EraseMode', 'none');
% set(hPlotSet, 'EraseMode', 'none');

% static limits of the plots
% xlim(hAxis, [minT(2), maxT(2)]);
xlim(hAxis, [min( sVar.infoND(:, 4) ), max( sVar.infoND(:, 4) )]);
ylim(hAxis, [minT(1) * 0.9 , maxT(1) * 1.1]);
title(hAxis, sprintf('Temperatures'))
hold off

end