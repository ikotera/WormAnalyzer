classdef durationCalculator < dataAllocator
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        dc________________;
        durationsPerWorm;
        durationsPerBehav;
        meanPerWorm;
        sumPerWorm
        countPerWorm;
    end
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    methods
        function dc = durationCalculator(mb, C)
            cm = mb.cropMatrixBehavior(C);                                          % Get cropped matrix specified behavior
            dc = dc@dataAllocator(cm);                                              % Inherit from the superclass
            
            dc.analysis = 'durations';
            
            dpw = cell(dc.numWorms, 1);
            dpb = [];
            for wm = 1:dc.numWorms
                dpw{wm} = sum( dc.lengthBehavior( dc.behaviorIndex, cm.matrix(:, wm), false, false) );
                dpb = [dpb; dpw{wm}'];                                              % Place all behaviors in a vector
            end

%             dc.durationsPerWorm = dpw;
%             dc.durationsPerBehav = dpb;
%             dc.meanPerWorm = cellfun(@mean, dpw);
%             dc.meanPerWorm( isnan(dc.meanPerWorm) ) = 0;
%             dc.sumPerWorm = cellfun(@sum, dpw);
%             dc.countPerWorm = cellfun(@(x) size(x, 2), dpw);
            
%             dc.getStats;

            dc.lengths = statManager(dpb, false);
        end
    end 
end

%#ok<*AGROW>

