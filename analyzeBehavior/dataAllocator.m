classdef dataAllocator < handle
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        da________________;
        matrixBehavior;
        numPoints;
        numWorms;
        analysis;
%         behavior;
%         behaviorIndex;
        phase;
        phaseIndex;
        nameMutant;
        behaviors = {'forward', 'reverse', 'turn', 'pause'};
        
        flgIgnoreFirstState;
        flgIgnoreLastState;
        flgCountNonTransition;
        secondsToAnalyze = nan;
        threshMinLength;
    end
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    methods
        function da = dataAllocator(cm, param)
            [da.numPoints, da.numWorms] = size(cm.matrix);
            da.matrixBehavior = cm.matrix;
%             da.behavior = cm.behavior;
%             da.behaviorIndex = cm.behaviorIndex;
            da.phase = cm.phase;
            da.phaseIndex = cm.phaseIndex;
            da.nameMutant = cm.nameMutant;
            
            da.flgIgnoreFirstState = param.flgIgnoreFirstState;
            da.flgIgnoreLastState = param.flgIgnoreLastState;
            da.flgCountNonTransition = param.flgCountNonTransition;
            da.secondsToAnalyze = param.secondsToAnalyze;
            da.threshMinLength = param.threshMinLength;
        end
    end
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    methods (Access = protected)
        
        function lg = lengthBehavior(da, idxBehav, vecBehav)
            q = diff([0 vecBehav' 0] == idxBehav);                                  % Running difference of the vector
            f = find(q == 1);
            l = find(q == -1);
            if da.flgIgnoreFirstState && ~isempty(f) && f(1) == 1
                f(1) = [];
                l(1) = [];
            end
            if da.flgIgnoreLastState && ~isempty(l) && l(1) == numel(vecBehav) + 1
                f(end) = [];
                l(end) = [];
            end
            lg = l - f;    
            lg = lg ./ 10;                                                          % Sampling rate = 10 Hz
        end
%=================================================================================================================================
        function adjustMatrix(da, secondsToAnalyze)
            if exist('secondsToAnalyze', 'var')
                da.secondsToAnalyze = secondsToAnalyze;
            end
            if ~isnan(da.secondsToAnalyze)
                da.matrixBehavior = da.matrixBehavior(1:da.secondsToAnalyze * 10, :);
                da.numPoints = size(da.matrixBehavior, 1);
            end
        end
    end
end
