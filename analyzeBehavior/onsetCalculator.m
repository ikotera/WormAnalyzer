classdef onsetCalculator < dataAllocator
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        oc________________;
        onsets;
    end
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    methods
        function oc = onsetCalculator(df, C, param)
            cm = df.cropMatrixBehavior(C);                                              % Get cropped matrix specified behavior
            oc = oc@dataAllocator(cm, param);                                           % Inherit from the superclass

            oc.adjustMatrix(oc.secondsToAnalyze);
            opw = nan(oc.numWorms, 1);
            for b = 1:df.nBehaviors
                for wm = 1:oc.numWorms
                    r = find(cm.matrix(1:oc.secondsToAnalyze * 10, wm) == b, 1, 'first');
                                                                                        % Find the onset of given behavior in the
                                                                                        % specified time period (secondsToAnalyze)
                    
                    r = r - 1;                                                          % First frame = 0s
                    r = r / 10;                                                         % Sampling rate = 10 Hz
                    if ~isempty(r)
                        opw(wm) = r;
                    end
                end
                opw( isnan(opw) ) = [];                                                 % Get rid of NaNs
                if oc.flgIgnoreFirstState
                    opw(opw == 0) = [];
                end
                if isempty(opw)
                    opw = nan;
                end
                OPW{b, 1} = opw;
            end
            oc.onsets = statManager(OPW, false, 'b');
        end
    end 
end

%#ok<*AGROW>

