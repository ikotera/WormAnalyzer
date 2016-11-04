classdef lengthCalculator < dataAllocator
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        lc________________;
        lengths;
    end
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    methods
        function lc = lengthCalculator(df, p, param)
            cm = df.cropMatrixBehavior(p);                                  % Get cropped matrix as a structure
            lc = lc@dataAllocator(cm, param);                                      % Inherit from superclass 
            
            lc.analysis = 'lengths';
            
            dt = cell(lc.numWorms, 1);
            for b = 1:df.nBehaviors
                for wm = 1:lc.numWorms
                    dt{wm} = lc.lengthBehavior( b, cm.matrix(:, wm) );
                end
                DT{b, 1} = [dt{:}]';                                              % Convert all cell components to an array
            end
            
            lc.lengths = statManager(DT, false, 'b');

        end
    end
end
%#ok<*AGROW>

