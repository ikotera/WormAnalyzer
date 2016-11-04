function extractCorrelations


    str = {'N2', 'nsy-1', 'nsy-7'};
    
    for s = 1:3
        processStrain(str{s});
    end

end

function processStrain(strain)
%     strain = 'nsy-7';

    pathB = ['\\101.101.1.207\working\', strain];
    pathN = ['\\MICROMANAGER\Ippei3\working\', strain];
    
    cm = correlationManager;
    cm.getManagers(pathN, pathB);
    cm.setParameters(false, 0, 0);
%     cm.setParameters(true, 45, 70);
%     cm.setParameters(true, 60, 90);
    cm.preparePlots;
    cm.manageXcorrs;

%     plotXcorrs(cm, cm.behaviors.TS{1}.Time, cm.behaviors.probabilities, cm.neurons.stats.Mean,...
%         cm.corrRatio, ['Raw Ratios and Behaviors, ', strain]);
    plotXcorrs(cm, cm.behaviors.TS{1}.Time, cm.behaviors.probabilities, cm.neurons.stats.Derivative,...
        cm.corrDerivative, ['Derivatives and Behaviors, ', strain]);

    delete(cm);
end

function plotXcorrs(cm, T, B, N, C, ttl)

    figure('Position', [100 100 2000 1200], 'Color', 'w');
    suptitle([ttl, char(10)]);

    mp = colormap(cm.bm.colormapBehavior);
    propLabel = {'Rotation', 45, 'Position', [cm.corrTimeMin-5 0 0], 'HorizontalAlignment', 'right'};
    n = 1;
    for nn = 0:cm.numNeurons
        
        for nb = 0:cm.numBehaviors
            if nn == 0 && nb >= 1   % For behavior plots
                subplot(cm.numNeurons + 1, cm.numBehaviors + 1, n);
                plot(T(cm.idxNonNan), B(cm.idxNonNan, nb), 'LineWidth', 1.5);
                title(cm.behaviors.list{nb});                
            elseif nn >= 1          % For neurons and xcorrs
                subplot(cm.numNeurons + 1, cm.numBehaviors + 1, n);
                if nb == 0          % For neurons
                    plot(T(cm.idxNonNan), N{nn}(cm.idxNonNan), 'LineWidth', 1.5);
                    ylabel(cm.neurons.stats.Properties.RowNames{nn}, propLabel{:});
                else                % For xcorrs
                    hold on
                    plot(C{nn, nb}{:}.lags, C{nn, nb}{:}.r, 'Color', mp(nb+1, :), 'LineWidth', 1.5);
                    xlim([min(C{nn, nb}{:}.lags) max(C{nn, nb}{:}.lags)]);
                    line(C{nn, nb}{:}.maxLag, C{nn, nb}{:}.maxR, 'Marker', 'o');
                    text(C{nn, nb}{:}.maxLag + 10, C{nn, nb}{:}.maxR,...
                        ['lag = ', num2str(C{nn, nb}{:}.maxLag), ', r = ', num2str(C{nn, nb}{:}.maxR)]);
                    hold off
                end
            end
            n = n + 1;
        end
    end

end

