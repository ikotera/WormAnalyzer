function extractAllWorms(pathInput)
% This function plots heat map and time series of worm behaviors. Requires behaviorManager.m.

%=================================================================================================================================
%% Initiations
bm = behaviorManager;
bm.readWorms(pathInput);
rateSampling = 10;
bm.resampleTimeSeries(rateSampling);
%=================================================================================================================================
%% Plot heat map of behaviors
figure('Position', [100 100 940 300]);
imagesc(bm.behaviors.resampled');
set(gca, 'Position', [0.03 0.08 0.95 0.83], 'XTickLabel', 50:50:300);
set(findall(gcf, '-property', 'FontSize'), 'FontSize', bm.sizeFont);
title(bm.nameStrain);
caxis([0 4]);
colormap(bm.colormapBehavior);                                              
%=================================================================================================================================                                                                      
%% Plot Behavior Probabilities                                                             
bm.getProbabilitiesAtEachTimePoint;
% [peaks, fwhm] = mspeaks(bm.timepoints, bm.probabilities(:, 2), 'NoiseEstimator', 0.2);
AL = 0.35; % Alpha value of error bars on the plot
figure('Position', [100 100 940 300]);
set(gca, 'Position', [0.03 0.08 0.95 0.83], 'XTickLabel', 50:50:300);
tp = bm.timepoints;
pb = bm.probabilities;
ci = bm.CI99;
nn = any(~isnan(pb), 2);
tp = tp(nn); 
pb = pb(nn, :); 
ci = ci(nn, :); 
hold on
errorbarShade(tp, pb(:, 1), ci(:, 1), [0.3 1.0 0.3], AL); ylim([0 1.1]); xlim([1 bm.nTimepoints]);
errorbarShade(tp, pb(:, 2), ci(:, 2), [1.0 0.3 0.3], AL); 
errorbarShade(tp, pb(:, 3), ci(:, 3), [0.5 0.5 1.0], AL); 
errorbarShade(tp, pb(:, 4), ci(:, 4), [0.9 0.9 0.1], AL);
% line(peaks(:,1), peaks(:,2), 'LineStyle', 'none', 'Marker', 'X');
title(bm.nameStrain);
% line(fwhm(:,1), peaks(:,2) / 2, 'LineStyle', 'none', 'Marker', 'o');
% line(fwhm(:,2), peaks(:,2) / 2, 'LineStyle', 'none', 'Marker', 'o');
hold off
set(findall(gcf, '-property', 'FontSize'), 'FontSize', bm.sizeFont);
%=================================================================================================================================
%% Save Results
behaviorsResampled = bm.behaviors.resampled; %#ok<NASGU>
% save([pathInput, '\', 'behaviorsResampled_', bm.nameStrain, '.mat'], 'behaviorsResampled');
bm.saveObject;
delete(bm);

end