classdef transitionCalculator < dataAllocator
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        tc________________;
        transitionMatrix;
        adjacencyMatrix;

        stateLabels;                                            % State labels created by bwlabel
        numStateLabels;                                         % Number of state labels in each worm
        posTransitions;                                         % Number of transition in each worm

        edgeThresh = 3;

        lengthsTransition;
        ratesTransition;
        lengthsExit;
        ratesExit;
        lengthsPrevious;
        ratePrevious;
        countsTransition;
        countsExit;
        totalTransition;
        
        numBehaviors;
%         flgIgnoreFirstState;
%         flgIgnoreLastState;
%         flgCountNonTransition;
%         threshMinLength;
    end
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods
        function tc = transitionCalculator(df, p, param)

            tc = tc@dataAllocator( df.cropMatrixBehavior(p), param );      % Inherit all fields from cropped struct via dataAllocator
            
            tc.numBehaviors = df.nBehaviors;
            tc.stateLabels = nan( [size(tc.matrixBehavior), tc.numBehaviors] );         % State labels created by bwlabel
            tc.numStateLabels = cell(tc.numWorms, tc.numBehaviors);
            
            [X, S, W, ~, ~, ~] = getVariables(tc);
            tc.posTransitions = cell(S, S, W);
            
            [Q, P] = meshgrid(1:S, 1:S);
            Y = [X, zeros(size(X, 1), 1)];                          % Zero-pad for concatenation
            funCount = @(p, q)numel(strfind(Y(:)', [p, q]));        % Counts p->q (col->row) transitions
            R = reshape(arrayfun(funCount, P, Q), S, S);            % Raw adj matrix
            tc.transitionMatrix = R;     
            R = R + 0.00000001;                                     % Probability matrix with minimum probability for graphing
            for ij = 1:S
                R(ij, ij) = 0;                                      % Get rid of self-loops
            end
            
            tc.adjacencyMatrix = double(R > tc.edgeThresh);         % Adjacency matrix

            tc.getAllTransitions;
        end
%=================================================================================================================================
        function getAllTransitions(tc)
            getLabels(tc);
            getTransitions(tc);
            getTransitionRates(tc);
        end
%=================================================================================================================================        
        function getLabels(tc)
            % Get sizes of each behavioral state for all the worms
            
            [X, S, W, ~, ~, ~] = getVariables(tc);

            for w = 1:W
                for s = 1:S
                    l = bwlabel(X(:, w) == s);                      % Label continuous block in an array
                    if tc.flgIgnoreFirstState && l(1)               % If the block is in the first element of the array
                        l = l - 1;                                  % Subtract the labels by 1, ie, ignore the first label
                        l(l < 0) = 0;                               % All the negatives be back to zero
                    end
                    if tc.flgIgnoreLastState && l(end)              % If the block is in the last element of the array
                        l( l == max(l) ) = 0;                       % Convert the largest label to zero
                    end                    
                    z = accumarray(l + 1, 1);                       % Count number of label elements in each state
                                                                    % (l + 1 because accumarray cannot count zero label)
                    tc.numStateLabels{w, s} = z(2:end);             % The first count is number of zero-label counts, so ignore it
                    tc.stateLabels(:, w, s) = l;
                end
            end
        end
%=================================================================================================================================        
        function getTransitions(tc)
            
            [X, S, W, ~, ~, ~] = getVariables(tc);
            
            % Find all combinations of transitions for all the worms
            t = cell(S, S);
            
            for w = 1:W
                t(:) = {NaN};
                for p = 1:S                                         % For all combination of behavioral states, p and q
                    for q = 1:S
                        if p ~= q
                            tr = strfind(X(:, w)', [p, q]);         % Find transitions, ie, non-equal consecutive elements
                            if isempty(tr)
                                if all(X(:, w)' == p) && tc.flgCountNonTransition
%                                     t{p, q} = size(X, 1);           % No transition means at least this length
                                    t{p, q} = inf;
                                else
                                    t{p, q} = NaN;
                                end
                            else
                                t{p, q} = tr;
                            end
                        end
                    end
                end
                
                flg = any( ~isnan([t{:}]) );                        % If any of the cell is non-NaN
                if tc.flgIgnoreFirstState && flg
                    m = cellfun(@(x) min(x), t(:, :), 'Un', false); % Find the earliest transition in all the behavioral combos;
                    m = cell2mat(m);
                    [mn, ind] = min( m(:) );
                    if ~isinf(mn)
                        t{ind}(t{ind}==mn) = [];                        % and delete it
                    end
                end

                e = cellfun(@(x) isempty(x), t, 'un', 1);           % Get indeces of empty cells
                if any(e(:))
                    t{e} = nan;      % Place NaNs in empty cells
                end
                tc.posTransitions(:, :, w) = t;
            end

        end
%=================================================================================================================================        
        function getTransitionRates(tc)
            
            [X, S, W, L, ~, T] = getVariables(tc);
            lt = cell(S, S);                                        % Lengths of behavior right before the transition (whole)
            
            % Calculate mean transition rates
            for w = 1:W
                for x = 1:S
                    for q = 1:S
                        t = T{x, q, w};                             % Transition of the given behavioral combo, p and q
                        if isinf(t)
                            if q == 2                               % Most forward state exists to reverse, thus q == 2
%                                 lt(p, q) = {[lt{p, q}, 50]};
                                lt(x, q) = {[lt{x, q}, tc.numPoints / 10]};
%                                 lt(p, q) = {[lt{p, q}, leng]};      % Add the size to the combo matrix
                            end
                        elseif ~isnan(t)
                            for n = 1:numel(t)                      % For all the transitions of the combo
                                l = L(t(n), w, x);                  % Get the type of behavior (label) for that combo
                                sz = sum(L(:, w, x) == l);          % Calculate the size of the label
                                sz = sz / 10;                       % Lengths in seconds, as sampling rate is 10 Hz
                                if sz > tc.threshMinLength
                                    lt(x, q) = {[lt{x, q}, sz]}; 
                                end
                            end
                        end
                    end
                end
            end
            
            tc.lengthsTransition = statManager(lt, false, 't');
            
            cv = sum(~isnan(X(:)));                    % Count of valid time-points
            ct = cellfun(@(x) numel(x) / cv, lt, 'Un', false);
            ce = num2cell( sum(cell2mat(ct), 2) );
            
            for x = 1:S
                le{x, 1} = [lt{x, :}];
                lp{x, 1} = [lt{:, x}];
            end
            
            rp = cellfun(@(x) 1 ./ x, lp, 'Un', false);
                    
            tc.lengthsExit = statManager(le, false, 'b');
            tc.lengthsPrevious = statManager(lp, false, 'b');
            tc.ratePrevious = statManager(rp, false, 'b');
            tc.countsTransition = statManager(ct, false, 't');
            tc.countsExit = statManager(ce', false, 'b');
            tc.totalTransition = statManager(num2cell( tc.lengthsTransition.mean .* cell2mat(ct) ), false, 't');
            
            rt = cellfun(@(x) 1 ./ x, lt, 'Un', false);
            re = cellfun(@(x) 1 ./ x, le, 'Un', false);
            
            tc.ratesTransition = statManager(rt, true, 't');
            tc.ratesExit = statManager(re, true, 'b');
        end
        
    end
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    methods (Access = private)
        function [X, S, W, L, B, T] = getVariables(tc)
            X = tc.matrixBehavior;                                  % Behavior matrix for the specified time window
            S = tc.numBehaviors;                                    % Number of behavioral states
            W = tc.numWorms;                                        % Number of worms
            L = tc.stateLabels;                                     % State labels created by bwlabel
            B = tc.numStateLabels;                                  % Number of state labels in each worm
            T = tc.posTransitions;
        end
    end
end
%#ok<*AGROW>

