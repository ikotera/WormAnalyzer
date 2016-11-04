classdef neuronManager < abstractManager
    %neuronManager Extract all the neurons that are labeled in neurons.mat file.

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        nm________________;

        flgMergeLR;                         % True if left and right neurons are treated as a same group of neurons
        flgMeanLR;                          % True if taking means of left and right neurons
        modeNormalization;
        modeHeater;
        flgModules;
        flgSynchLaser;
        synchFirstLaserFromStart = 50;
        synchLastLaserToEnd = 50;
        synchDuration = 2600;
        synchShiftStart = 0;
        synchShiftEnd = 0;
        zapPower;
        zapDuration;
        planLaser;
        laserAmplitude;
        laserTime;
        
        lenModule;
        modulesLaser;
        numPlanes;
        numNeurons;
        infoND;
        neurons;
        selectedNeurons = [];
        resampled;
        
    end
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods
        function nm = neuronManager()
            nm = nm@abstractManager();
        end
%=================================================================================================================================
        function bool = parseFiles(nm, RS)
            warning('off', 'MATLAB:linearinter:noextrap');
            nm.neurons.rateSampling = RS;
            cn = 1;
                
            for nf = 1:nm.numFiles
                NR = nm.loadMat(nf);
                cn = nm.resampleTimeseries(nf, cn, NR);
            end
            
            if ~isfield(nm.neurons, 'resampled') || isempty(nm.neurons.resampled)
                prt('No labelled neuron found.');
                bool = false;
                return
            else
                bool = true;
            end
            warning('on', 'MATLAB:linearinter:noextrap');
        end
%=================================================================================================================================
        function NR = loadMat(nm, ixFile)
            
            % Load the mat files and get a list of all the neurons
            [nm.listFiles(ixFile).parent, ~, ~] = fileparts(nm.listFiles(ixFile).name);
            nm.listFiles(ixFile).parent = [nm.listFiles(ixFile).parent, '\'];
            s1 = load([nm.listFiles(ixFile).parent, ls([nm.listFiles(ixFile).parent, 'Variables*.mat'])]);
            nm.modeHeater = s1.modeHeater;
            nm.infoND{ixFile, 1} = s1.infoND;
            
            if isfield(s1, 'modulesLaser') && ~isnan(s1.modulesLaser) && s1.modulesLaser > 1
                nm.flgModules = true;
                nm.lenModule = round(s1.duration / s1.modulesLaser);
                nm.modulesLaser = s1.modulesLaser;
            else
                nm.flgModules = false;
                nm.modulesLaser = 1;
                nm.lenModule = s1.duration;
            end
            if nm.flgSynchLaser && isfield(s1, 'planLaser') && s1.planLaser(1) ~= nm.synchFirstLaserFromStart
                nm.synchShiftStart = s1.planLaser(1) - nm.synchFirstLaserFromStart;
                nm.synchShiftEnd = s1.duration - nm.synchDuration - nm.synchFirstLaserFromStart;
            else
                nm.synchShiftStart = 0;
                nm.synchShiftEnd = 0;
                nm.synchDuration = nm.lenModule;
            end
            s2 = load([nm.listFiles(ixFile).name], 'neurons');
            NR = s2.neurons;
            nm.listFiles(ixFile).label = nm.listFiles(ixFile).parent(end - 11:end - 1);
            nm.numPlanes = numel(NR);
            nm.numNeurons = cellfun(@numel, NR);
            
            nm.getStrainName;
            
            if ixFile == 1 && strcmp(s1.modeHeater, 'zap')
                nm.zapPower = s1.zapPower;
                nm.zapDuration = s1.zapDuration;
                nm.planLaser = s1.planLaser - nm.synchShiftStart;
                nm.planLaser = nm.planLaser( nm.planLaser <= (nm.lenModule - nm.synchShiftEnd - nm.synchShiftStart) );
            end
        end
%=================================================================================================================================
        function cnt = resampleTimeseries(nm, ixFile, cnt, NR)
            
            try
                lenRatio = length(NR{1}{1}.('int_ratio'));
            catch
            end
            
            % Extract ratios, and resample them
            for np = 1:nm.numPlanes
                for nn = 1:nm.numNeurons(np)
                    nameNeuron = NR{np}{nn}.('name');
                    if length(nameNeuron) >= 4 && ~( strcmp(nameNeuron(4), 'L') || strcmp(nameNeuron(4), 'R') )
                        lenName = 4;
                    else
                        lenName = 3;
                    end
                    if ~strcmp(nameNeuron(1:2), 'ne') && ...
                            ( isempty(nm.selectedNeurons)|| any( strcmp(nameNeuron(1:lenName), nm.selectedNeurons) ) )
                        
                        timePoints = nm.infoND{ixFile}(nm.infoND{ixFile}(:, 2) == np, 4);
                        
                        try
                            ratioRaw = NR{np}{nn}.('int_ratio')( 1:length(timePoints) );
                        catch
                            ratioRaw = NR{np}{nn}.('int_ratio')( 1:lenRatio );
                            timePoints = timePoints(1:lenRatio, :);
                        end
                        if size(ratioRaw, 1) < size(ratioRaw, 2)
                            ratioRaw = ratioRaw';
                        end
                        nm.neurons.labelled{nn, 1} = nameNeuron;
                        nm.neurons.labelled{nn, 2} = ratioRaw;
                        nm.neurons.labelled{nn, 3} = timePoints;
                        for md = 1:nm.modulesLaser
                            
                            startModule = nm.lenModule * (md - 1) + nm.synchShiftStart;
                            endModule = nm.lenModule * md - nm.synchShiftEnd;
                            timePoints( timePoints(:, 1) >= startModule &...
                                timePoints(:, 1) <  endModule, 2) = md;
                            rR = ratioRaw(timePoints(:, 2) == md);
                            tP = timePoints(timePoints(:, 2) == md);
                            
                            % Create time series object
                            objTs = timeseries(rR, tP, 'Name', 'neuron');
                            
                            if nm.flgModules
                                if isodd(md)
                                    nameNeuron = [NR{np}{nn}.('name'), '_S'];
                                else
                                    nameNeuron = [NR{np}{nn}.('name'), '_N'];
                                end
                            end
                            
                            nm.neurons.moduled{cnt, 1} = nameNeuron;
                            nm.neurons.moduled{cnt, 2} = rR;
                            nm.neurons.moduled{cnt, 3} = tP - nm.lenModule * (md - 1);
                            
                            % Resample the TS to uniform intervals
                            objResampled  = resample(objTs, startModule:1/nm.neurons.rateSampling:endModule, 'linear');
                            objResampled.Time = objResampled.Time - startModule;
                            nm.neurons.resampled{cnt, 1} = nameNeuron;
                            nm.neurons.resampled{cnt, 2} = objResampled.data;
                            nm.neurons.resampled{cnt, 3} = nm.listFiles(ixFile).parent(end - 11:end - 1);
                            nm.neurons.resampled{cnt, 4} = ixFile; % Record the file number for plotting later on
                            nm.neurons.resampled{cnt, 5} = nm.numFiles; % Record the total number of files
                            nm.neurons.resampled{cnt, 6} = objResampled;
                            
                            prt(cnt);
                            cnt = cnt + 1;
                        end
                    end
                end
            end
            if isfield(nm.neurons, 'labelled') && ~isempty(nm.neurons.labelled)
                nm.neurons.labelled(cellfun( @isempty, nm.neurons.labelled(:,2) ), :) = [];
            end
        end
%=================================================================================================================================
        function mergeNeuronsLR(nm)
            RSP = nm.neurons.resampled;
            sizeN = size(RSP, 1);
            MRG = cell(sizeN, 1);
            
            for sn = 1:sizeN
                if strcmp(RSP{sn, 1}(1:3), 'AWC')                                           % For AWC neurons
                    MRG{sn} = RSP{sn};
                else                                                                        % All other neurons
                    if strcmp(RSP{sn, 1}(end-1), '_')                                       % Multiple modules (_N, _S)
                        if strcmp(RSP{sn}(end-2), 'L') || strcmp(RSP{sn}(end-2), 'R')       % LR neurons
                            MRG{sn} = [RSP{sn}(1:end-3), RSP{sn}(end-1:end)];
                        else
                            MRG{sn} = [RSP{sn}(1:end-2), RSP{sn}(end-1:end)];
                        end
                    else
                        if strcmp(RSP{sn, 1}(end), 'L') || strcmp(RSP{sn}(end), 'R')        % LR neurons
                            MRG{sn} = RSP{sn}(1:end-1);
                        else
                            MRG{sn} = RSP{sn}(1:end);
                        end
                    end
                end
            end
            nm.neurons.resampled(:, 1) = MRG;
        end
%=================================================================================================================================
        function sortNeurons(nm)
            if nm.flgMergeLR
                nm.mergeNeuronsLR;
            end
            RSP = nm.neurons.resampled;
            
            % The first neuron
            SN{1, 1} = RSP{1, 1};
            SN{1, 2}{1, 1} = RSP{1, 2}; % Ratio series
            SN{1, 2}{1, 2} = RSP{1, 3}; % Date and time of acquisition
            SN{1, 2}{1, 3} = RSP{1, 4}; % File number
            SN{1, 2}{1, 4} = RSP{1, 5}; % Total number of files
            SN{1, 2}{1, 5} = RSP{1, 6}; % Total number of files
            
            % Put all the neurons into groups
            for nln = 1:size(RSP, 1)-1
                
                label1 = SN(:, 1);
                label2 = RSP{nln+1, 1};
                ratio2 = RSP{nln+1, 2};
                date2 = RSP{nln+1, 3};
                nfNeuron2 = RSP{nln+1, 4};
                tnNeuron2 = RSP{nln+1, 5};
                ts2 = RSP{nln+1, 6};
                
                if any(strcmp(label1, label2)) % If the neuron label matches the existing groups
                    SN{strcmp(label1, label2), 2}{end+1, 1} = ratio2;
                    SN{strcmp(label1, label2), 2}{end, 2} = date2;
                    SN{strcmp(label1, label2), 2}{end, 3} = nfNeuron2;
                    SN{strcmp(label1, label2), 2}{end, 4} = tnNeuron2;
                    SN{strcmp(label1, label2), 2}{end, 5} = ts2; 
                else
                    SN{end+1, 1} = label2; %#ok<AGROW> % otherwise create a new group
                    SN{end, end}{end+1, 1} = ratio2;
                    SN{end, end}{end, 2} = date2;
                    SN{end, end}{end, 3} = nfNeuron2;
                    SN{end, end}{end, 4} = tnNeuron2;
                    SN{end, end}{end, 5} = ts2;
                end
            end

            if nm.flgMeanLR
    
                for cs = 1:size(SN, 1)
                    
                    stamps = SN{cs, 2}(:, 2);
                    st = 1;
                    while st < length(stamps)
                        stampThisCell = SN{cs, 2}{st, 2};
                        flgMean = strcmp(stamps, stampThisCell);
                        flgMean(1:st) = false;
                        if any(flgMean)
                            SN{cs, 2}{st, 1} = mean(cat(2,...
                                SN{cs, 2}{st, 1}, SN{cs, 2}{flgMean, 1}), 2);
                            SN{cs, 2}(flgMean, :) = [];
                        end
                        stamps = SN{cs, 2}(:, 2);
                        st = st + 1;
                    end
                end
            end
            
            SN = sortrows(SN, 1);
            
            for n = 1:size(SN, 1)
                SN{n, 1} = strrep(SN{n, 1}, 'ON', '^{ON}');
                SN{n, 1} = strrep(SN{n, 1}, 'OFF', '^{OFF}');
            end

            nm.neurons.sorted = SN;
            
        end
%=================================================================================================================================
        function getStats(nm)
            
            numGroups = size(nm.neurons.sorted, 1);
            
            nm.neurons.names = nm.neurons.sorted(:, 1);
            nameVar = {'Ratio', 'Time' 'Mean', 'SD', 'SE', 'CI83', 'Derivative', 'NumNeurons'};
            cl = cell( numGroups, numel(nameVar) );
            stats = cell2table( cl, 'VariableName', nameVar, 'RowNames', nm.neurons.names);   

            for nn = 1:numGroups
                
                clear ratios ratioNorm
                ratios = cat(2, nm.neurons.sorted{nn, 2}{:, 1});
                ratioNorm = nan( size(ratios) );

                numNeu = size(ratios, 2);
                
                % Normalization
                for rt = 1:numNeu
                    switch nm.modeNormalization
                        case 'normalize'
                            ratioNorm(:, rt) = ( ratios(:, rt) - min(ratios(:, rt)) ) /...
                                ( max(ratios(:, rt)) - min(ratios(:, rt)) ); % Normalize
                            
                        case 'bottom'
                            ratioNorm(:, rt) = ( ratios(:, rt) - min(ratios(:, rt)) ); % Backgroud subtraction
                            
                        otherwise
                            ratioNorm(:, rt) = ratios(:, rt);
                    end
                end

                % Calculate all stats
                stats.Ratio(nn) = {ratioNorm};
                stats.Time(nn) = {nm.neurons.sorted{1, 2}{1, 5}.Time};
                stats.Mean(nn) = {mean(ratioNorm, 2)};
                stats.SD(nn) = {std(ratioNorm, 0, 2)};
                stats.SE(nn) = {stats.SD{nn} ./ sqrt( size(ratioNorm, 2) )};
                stats.CI83(nn) = {stats.SE{nn} .* 1.386};
                stats.Derivative(nn) = {[nan; diff( stats.Mean{nn} )]};     % Time derivative + nan at the begining.
                stats.NumNeurons(nn) = {numNeu};
            end

            nm.neurons.stats = stats;
        end
%=================================================================================================================================
        function getLaserOutput(nm)
            switch nm.modeHeater
                case 'zap'
                    [nm.laserAmplitude, nm.laserTime] = parseZapPlan(nm.planLaser, nm.zapPower, nm.synchDuration, nm.zapDuration);
            end
        end
%=================================================================================================================================
        function saveStats(nm)
            stats = nm.neurons.stats; %#ok<NASGU>
            save([nm.pathInput, '\', 'stats.mat'], 'stats');
        end
%=================================================================================================================================
        function saveObject(nm)
            save([nm.pathInput, '\', 'neuronManager.mat'], 'nm');
        end
        
    end
    
end

