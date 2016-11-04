classdef fractionCalculator < dataAllocator
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        fc________________;
        fractions;
    end
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods
        function fc = fractionCalculator(df, C, param)
            cm = df.cropMatrixBehavior(C);
            fc = fc@dataAllocator(cm, param);                           % Inherit from the superclass

            B = fc.matrixBehavior;
%             nn = all(~isnan(B), 1);
            nc = sum(~isnan(B), 1);                                     % Non-NaN counts
%             S = size(B, 1);
            W = fc.numWorms;
            N = cell(df.nBehaviors, 1);
            for b = 1:df.nBehaviors
                N{b, 1} = arrayfun(@(x) sum(B(:, x) == b), (1:W));      % Count number of time-points for each state and behavior
            end

%             F = cellfun(@(x) (x(nn) ./ S)', N, 'Un', false);            % Get fractions for each behavior
            F = cellfun(@(x) (x ./ nc)', N, 'Un', false);               % Devide each count by number of valid time-point
            
            for c = 1:size(F, 1)
                F{c}( isnan(F{c}) ) = [];                               % Delete nans (caused by N ./ 0) from the cell array
%                 F{c}( F{c} == 0 ) = [];                                 % Delete 0's from the cell array
            end

            fc.fractions = statManager(F, false, 'b');

        end
    end

end