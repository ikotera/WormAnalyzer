classdef behaviorManager < abstractManager
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        bm________________;
        behaviors;
        probabilities;
        timepoints;
        timeShift = 3;
        nTimepoints;
        duration;
        SE;
        CI99;
        sizeFont = 11;
    end
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Access = public)
%=================================================================================================================================
        function bm = behaviorManager
            bm = bm@abstractManager();
            bm.behaviors.list = {'Forward'; 'Reverse'; 'Turn'; 'Pause'};

        end
%=================================================================================================================================        
        function readWorms(bm, path)

            b = bm.readFiles(path, 'worms.mat'); if ~b, return, end
            
            bm.behaviors.master = cell(bm.numFiles, 1);
            
            durPrev = [];
            for nf = 1:bm.numFiles
                
                [pathCurrent, ~, ~] = fileparts(bm.listFiles(nf).name);
                pathCurrent = [pathCurrent, '\']; %#ok<*AGROW>
                m = load([pathCurrent, ls([pathCurrent, 'Variables*.mat'])]);
                bm.behaviors.master{nf}.metadata = m;
                
                dur = m.duration;
                if ~isempty(durPrev) && dur ~= durPrev
                    error('Time duration must be the same for all the assays.');
                end
                
                s = load([pathCurrent, 'worms.mat'], 'worms');
                bm.listFiles(nf).label = pathCurrent(end - 11:end - 1);         % Folder name in YYMMDD-HHMM format
                numWorms = length(s.worms);                                     % Number of worms in the current file
                if numWorms > 0
                    bh = num2cell([s.worms(:).behaviors], 1);                   % Behavior data in a structure to cells
                    tp = [s.worms(1).timepoints];                               % Extract timepoints from structure
                    bm.behaviors.master{nf}.worms = bh;
                    bm.behaviors.master{nf}.timepoints = tp;
                    bm.behaviors.master{nf}.numWorms = numWorms;
                    
                    durPrev = dur;
                end
            end            

            bm.duration = dur;
            
            bm.getStrainName;

        end
%=================================================================================================================================        
        function resampleTimeSeries(bm, R)
            bm.behaviors.rateSampling = R;
            DR = bm.duration;
            ixB = 1;
            for nf = 1:bm.numFiles

                BH = bm.behaviors.master{nf}.worms;
                TP = bm.behaviors.master{nf}.timepoints + bm.timeShift;
                NW = bm.behaviors.master{nf}.numWorms;
%                 BH = cellfun(@(x) x(1:end-1), BH, 'Un', false);                 % Remove the last element of behavior (NaN)
%                 TP = TP(1:end-1);                                               % Remove the last element of timepoints (NaN)
                ts = cellfun(@(x) {timeseries(x, TP, 'Name', 'worm')}, BH);    % Create timeseries objects from behavior cells
                rt = cellfun(@(x) {resample(x, 0:1/R:DR, 'zoh')}, ts);       % Resample the ts with sampling rate (SR) 
                                                                                % and zero order hold (zoh)
                ixE = ixB + NW - 1;
                cRs(1, ixB:ixE) = cellfun(@(x) {x.Data}, rt);                % Resampled ts to cells
                RT(1, ixB:ixE) = rt;                                            % Resampled ts to cells
                ixB = ixE + 1;

            end

            cRs(cellfun(@isempty, cRs)) = [];                               % Get rid of empty cells
            RT(cellfun(@isempty, cRs)) = [];                               % Get rid of empty cells
            mnt = min( cellfun(@length, cRs) );                               % Find the shortest duration in all the worms
            cRs = cellfun(@(x) x(1:mnt), cRs, 'UniformOutput', false);      % Make a matrix with fixed number of time points
            mat = cat(2, cRs{1,:});                                           % Convert cell array to matrix
%             mat = mat(any(~isnan(mat), 2), :);                                  % Del rows ie all NaNs (ie, artifact at the end)
            bm.behaviors.resampled = mat( :, any(~isnan(mat), 1) );             % Del cols ie all NaNs (ie, empty worms)
            bm.behaviors.TS = RT;
        end
%=================================================================================================================================        
        function getProbabilitiesAtEachTimePoint(bm)
            
            bm.nTimepoints = size(bm.behaviors.resampled, 1);
            vw = sum(~isnan(bm.behaviors.resampled), 2);                        % Count valid worms(~isnan) at each time point

            for b = 1:4
                pr(:, b) = sum(bm.behaviors.resampled(:, :) == b, 2) ./ vw;     % Probabilities of behaviors at each time point
                se(:, b) = sqrt(pr(:, b) .* (1 - pr(:, b)) ./ vw);              % Standard error from probabilities
            end
            
            bm.probabilities = pr;
            bm.SE = se;
            bm.CI99 = se * 2.58;                                                % 99% confidence interval. Use 1.96 for 95% CI.
            bm.timepoints = (1:bm.nTimepoints)';

        end
%=================================================================================================================================
        function map = colormapBehavior(~, m)

            if ~exist('m', 'var')
                m = 5;
            end

            map = cat(1, ...
                [1      1       1  ], ...
                [0.3    1       0.3], ...
                [1      0.3     0.3], ...
                [0.5    0.5     1  ], ...
                [.9      .9     0.3]  ...
                );

            map = map(end-m+1:end, :);
            
            % Minimum value, 0, is reserved for NaNs
            % 0     no data    white
            % 1     forward    green
            % 2     reverse    red
            % 3     turn       blue
            % 4     pause      yellow
        end
%=================================================================================================================================
        function saveObject(bm)
            save([bm.pathInput, '\', 'behaviorManager.mat'], 'bm');
        end            
        
    end
    
end

