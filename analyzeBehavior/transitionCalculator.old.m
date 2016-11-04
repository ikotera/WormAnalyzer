classdef transitionCalculator < dataAllocator
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        tc________________;
        transitionMatrix;
        adjacencyMatrix;
        probabilityMatrix;
        objLengths;
%         meanLengthsEachState;
        meanLengths;
        seLengths;
        ci83Lengths;
        ci95Lengths;
        ci99Lengths;
        edgeThresh = 3;
        behaviors = {'forward', 'reverse', 'turn', 'pause'};
%         nameMutant;
        
        lengthsPretransitionPerWorm;
        lengthsPretransitionAllWorms;
        meanLengthPretreansitionPerWorm;
        meanLengthPretransitionAllWorms;
        countBehaviorsAllWorms;
        sdPretransitionAllWorms;
        sePretransitionAllWorms;
        ci83PretransitionAllWorms;
        ci95PretransitionAllWorms;
        ci99PretransitionAllWorms;
        transitionRateMatrix;
        numStates = 4;
        flgIgnoreFirstState = true;
    end
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    methods
        function tc = transitionCalculator(df, C)
            tc = tc@dataAllocator( df.cropMatrixBehavior(C) );      % Inherit all fields from cropped struct via dataAllocator
            
            X = tc.matrixBehavior;                                  % Behavior matrix for the specified time window
            S = tc.numStates;                                       % Number of behavioral states
            W = size(X, 2);                                         % Number of worms
            
            [Q, P] = meshgrid(1:S, 1:S);
            Y = [X, zeros(size(X, 1), 1)];                          % Zero-pad for concatenation
            funCount = @(p, q)numel(strfind(Y(:)', [p, q]));        % Counts p->q (col->row) transitions
            R = reshape(arrayfun(funCount, P, Q), S, S);            % Raw adj matrix
            tc.transitionMatrix = R;
            tc.lengthsPretransitionAllWorms = cell(S, S);           % Lengths of behavior right before the transition (whole)
            tc.lengthsPretransitionPerWorm = cell(S, S, W);         % Lengths of behavior right before the transition (per worm)
            tc.meanLengthPretreansitionPerWorm = nan(S, S, W);      % Means of above

            
            R = R + 0.00000001;                                     % Probability matrix with minimum probability for graphing
            for ij = 1:S
                R(ij, ij) = 0;                                      % Get rid of self-loops
            end
            
            
            
            
            % Get sizes of each behavioral state for all the worms
            L = nan( [size(X), S] );                                % State labels created by bwlabel
            B = cell(W, S);                                         % Number of state labels in each worm

            for w = 1:W
                for s = 1:S
                    l = bwlabel(X(:, w) == s);                      % Label continuous block in an array
                    if tc.flgIgnoreFirstState && l(1)               % If the block is in the first element of the array  
                        l = l - 1;                                  % Subtract the labels by 1, ie, ignore the first label
                        l(l < 0) = 0;                               % All the negatives be back to zero
                    end
                    z = accumarray(l + 1, 1);                       % Count number of label elements in each state
                                                                    % (l + 1 because accumarray cannot count zero label)
                    B{w, s} = z(2:end);                             % The first count is number of zero-label counts, so ignore it
                    L(:, w, s) = l;
                end
            end
            
            
            % Find all combinations of transitions for all the worms
            T = cell(S, S, W);                                      % Number of transitions in each worm
            t = cell(S, S);
            
            for w = 1:W
                t(:) = {NaN};
                for p = 1:S                                         % For all combination of behavioral states, p and q
                    for q = 1:S
                        if p ~= q
                            tr = strfind(X(:, w)', [p, q]);         % Find transitions, ie, non-equal consecutive elements
                            if isempty(tr)
                                t{p, q} = NaN;
                            else
                                t{p, q} = tr;
                            end
                        end
                    end
                end
                if tc.flgIgnoreFirstState
                    m = cellfun(@(x) min(x), t(:, :), 'Un', false); % Find the earliest transition in all the behavioral combos;
                    m = cell2mat(m);
                    [mn, ind] = min( m(:) );
                    t{ind}(t{ind}==mn) = [];                        % and delete it
                end
                T(:, :, w) = t;
            end
            
            % Calculate mean transition rates
            for w = 1:W
                for p = 1:S
                    for q = 1:S
                        t = T{p, q, w};                             % Transition of the given behavioral combo, p and q
                        if ~isnan(t)
                            for n = 1:numel(t)                      % For all the transitions in the combo
                                l = L(t(n), w, p);                  % Get the type of behavior (label) for that combo
                                sz(n) = sum(L(:, w, p) == l);       % Calculate the size of the label
                            end
                            leng = sz ./ 10;                        % Lengths in seconds, as sampling rate is 10 Hz
                                                                    % Add the size to the combo matrix
                            tc.lengthsPretransitionAllWorms(p, q) = {[tc.lengthsPretransitionAllWorms{p, q}, leng]};
                                                                    % Add the size to the combo/worm matrix
                            tc.lengthsPretransitionPerWorm(p, q, w) = {leng};
                                                                    % Add the per-worm mean to the combo/worm matrix
                            tc.meanLengthPretreansitionPerWorm(p, q, w) = mean(leng);
                        end
                    end
                end
            end
            
%             mmt = mean(bt.meanLengthPretreansition, 3,'omitnan') ./ 10;
%             mr = 1 ./ mmt;
            
%             mmt = cellfun(@(x) mean(x), tc.lengthsPretransitionAllWorms, 'Un', false);
            
            tc.meanLengthPretransitionAllWorms = cell2mat( cellfun(@(x) mean(x), tc.lengthsPretransitionAllWorms, 'Un', false) );
            tc.sdPretransitionAllWorms = cell2mat( cellfun(@(x) std(x), tc.lengthsPretransitionAllWorms, 'Un', false) );
            tc.countBehaviorsAllWorms = cell2mat( cellfun(@(x) numel(x), tc.lengthsPretransitionAllWorms, 'Un', false) );
            tc.sePretransitionAllWorms = cell2mat( arrayfun(@(x, y) x ./ sqrt(y), tc.sdPretransitionAllWorms, tc.countBehaviorsAllWorms, 'Un', false) );
            tc.sePretransitionAllWorms = tc.sdPretransitionAllWorms ./ sqrt(tc.countBehaviorsAllWorms);
            tc.ci83PretransitionAllWorms = tc.sePretransitionAllWorms .* 1.386;
            tc.ci95PretransitionAllWorms = tc.sePretransitionAllWorms .* 1.96;
            tc.ci99PretransitionAllWorms = tc.sePretransitionAllWorms .* 2.58;
            tc.transitionRateMatrix = 1 ./ tc.meanLengthPretransitionAllWorms;
            tc.probabilityMatrix = tc.transitionRateMatrix;
            
%             bt.probabilityMatrix = R * 60 ./  ( ( size(X, 1) * size(X, 2) ) / 10 ); % Events per minute (wrong again!!)          
%             bt.probabilityMatrix = R./ sum(R(:));                   % Probability matrix (wrong!)

            tc.adjacencyMatrix = double(R > tc.edgeThresh);         % Adjacency matrix

            for b = 1:tc.numStates
                C{1} = tc.behaviors{b};                             % For each behavior
                lc(b) = lengthCalculator(df, C);                    % Instantiate lengthCalculator objects
            end
            
            tc.meanLengths = [lc.meanPerBehav];
            tc.seLengths = [lc.seAllWorms];
            tc.ci83Lengths = [lc.ci83AllWorms];
            tc.ci95Lengths = [lc.ci95AllWorms];
            tc.ci99Lengths = [lc.ci99AllWorms];
            tc.objLengths = lc;                                     % Copy mean lengthCalculator objects to this instance
        end
        
%         function getLabels
%         end
%         
%         function getTransitions
%         end
%         
%         function getTransitionRates
%         end
        
    end
end
%#ok<*AGROW>

