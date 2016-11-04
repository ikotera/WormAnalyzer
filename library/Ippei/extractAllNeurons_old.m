function extractAllNeurons_old(pathInput)
% extractAllNeurons(pathInput);
%
% Extract all the neurons that are labeled in neurons.mat file. Do some basic manipulations of the
% ratio values, and categorize the neurons according to the neuron labels.


% numResampledTimePoints = 540; % Number of time points after resampling
flgMergeLR = true; % True if left and right neurons are treated as a same group of neurons
flgMeanLR = false; % True if taking means of left and right neurons
modeNormalization = 'normalize';

% Get a list of neurons.mat files in the folder and subfolders
listFiles = rdir([pathInput, '\**\neurons.mat']);
numFiles = numel(listFiles);

cn = 1;

for nf = 1:numFiles
    
    % Load the mat files and get a list of all the neurons
    [path, ~, ~] = fileparts(listFiles(nf).name);
    path = [path, '\'];
    s = load([path, ls([path, 'Variables*.mat'])]);
    infoND = s.infoND;
%     if exist('modulesLaser', 'var') && ~isnan(modulesLaser) && modulesLaser > 1
    if isfield(s, 'modulesLaser') && ~isnan(s.modulesLaser) && s.modulesLaser > 1
        flgModules = true;
        lenModule = round(s.duration / s.modulesLaser);
        modulesLaser = s.modulesLaser;
    else
        flgModules = false;
        modulesLaser = 1;
        lenModule = s.duration;
    end
        
%     if nf == 1
%         numResampledTimePoints = ceil(max(infoND(:, 4))); %#ok<NODEF>
%     end
    
    load([path, 'neurons.mat'], 'neurons');
    
    listFiles(nf).label = path(end - 11:end - 1);
    
    numPlanes = numel(neurons);
%     for np = 1:numPlanes
%         numNeurons(np) = numel(neurons{np});
%     end
    numNeurons = cellfun(@numel, neurons);
    
    
    warning('off', 'MATLAB:linearinter:noextrap');

    % Extract ratios, and resample them
    for np = 1:numPlanes
        for nn = 1:numNeurons(np)
            nameNeuron = neurons{np}{nn}.('name');
            if ~strcmp(nameNeuron(1:2), 'ne')
                
                % timePoints = infoND(infoND(infoND(:, 2) == np), 4);
                timePoints = infoND(infoND(:, 2) == np, 4);
                ratioRaw = neurons{np}{nn}.('int_ratio')( 1:length(timePoints) );
                
                for md = 1:modulesLaser
                    
                    startModule = lenModule * (md - 1);
                    endModule = lenModule * md;
                    timePoints( timePoints(:, 1) >= startModule &... 
                                timePoints(:, 1) <  endModule, 2) = md;
                    rR = ratioRaw(timePoints(:, 2) == md);
                    tP = timePoints(timePoints(:, 2) == md);
                    
                    % Create time series object
                    objTs = timeseries(rR, tP, 'Name', 'neuron');
                    
                    if flgModules
                        if isodd(md)
                            nameNeuron = [neurons{np}{nn}.('name'), '_S'];
                        else
                            nameNeuron = [neurons{np}{nn}.('name'), '_N'];
                        end
                    end
                    
                    % Resample the TS to uniform intervals
                    objResampled  = resample(objTs, startModule:1:endModule, 'linear');
                    labelledNeurons{cn, 1} = nameNeuron;
                    labelledNeurons{cn, 2} = objResampled.data;
                    labelledNeurons{cn, 3} = path(end - 11:end - 1);
                    labelledNeurons{cn, 4} = nf; % Record the file number for plotting later on
                    labelledNeurons{cn, 5} = numFiles; % Record the total number of files
                    
                    prt(cn);
                    
                    cn = cn + 1;
                end
                
            end
        end
    end
    
%     pause(1);
    
end

if ~exist('labelledNeurons', 'var') || isempty(labelledNeurons)
    prt('No labelled neuron found.');
    return
end


if flgMergeLR
%     if flgModules
        labelledNeurons(:, 1) = mergeNeurons(labelledNeurons(:, 1));
%         labeledNeurons(:, 1) = cellfun(@(x) [x(1:end-2), x(end-1:end)], labeledNeurons(:, 1), 'UniformOutput', false);
%     else
%         labeledNeurons(:, 1) = cellfun(@(x) x(1:end-1), labeledNeurons(:, 1), 'UniformOutput', false);
%     end
end


% The first neuron
sortedNeurons{1, 1} = labelledNeurons{1, 1};
sortedNeurons{1, 2}{1, 1} = labelledNeurons{1, 2}; % Ratio series
sortedNeurons{1, 2}{1, 2} = labelledNeurons{1, 3}; % Date and time of acquisition
sortedNeurons{1, 2}{1, 3} = labelledNeurons{1, 4}; % File number
sortedNeurons{1, 2}{1, 4} = labelledNeurons{1, 5}; % Total number of files

% Put all the neurons into groups
for nln = 1:size(labelledNeurons, 1)-1
    
    labelNeuron1 = sortedNeurons(:, 1);
    labelNeuron2 = labelledNeurons{nln+1, 1};
    ratioNeuron2 = labelledNeurons{nln+1, 2};
    dateNeuron2 = labelledNeurons{nln+1, 3};
    nfNeuron2 = labelledNeurons{nln+1, 4};
    tnNeuron2 = labelledNeurons{nln+1, 5};
    
%     % Use only first three letters of neurons if it's specified to do so
%     if flgMergeLR
%         if flgModules
%             sortedNeurons{1, 1} = [sortedNeurons{1, 1}(1:3), sortedNeurons{1, 1}(5:6)];
%             labelNeuron1 = cellfun(@(x) [x(1:3), x(5:6)], labelNeuron1, 'UniformOutput', false);
%             labelNeuron2 = [labelNeuron2(1, 1:3), labelNeuron2(1, 5:6)];
%         else
%             sortedNeurons{1, 1} = sortedNeurons{1, 1}(1:3); % Replace the label of the first neuron
%             labelNeuron1 = cellfun(@(x) x(1:3), labelNeuron1, 'UniformOutput', false);
%             labelNeuron2 = labelNeuron2(1, 1:3);
%         end
%     end
    
    if any(strcmp(labelNeuron1, labelNeuron2)) % If the neuron label matches the existing groups
        sortedNeurons{strcmp(labelNeuron1, labelNeuron2), 2}{end+1, 1} = ratioNeuron2;
        sortedNeurons{strcmp(labelNeuron1, labelNeuron2), 2}{end, 2} = dateNeuron2;
        sortedNeurons{strcmp(labelNeuron1, labelNeuron2), 2}{end, 3} = nfNeuron2;
        sortedNeurons{strcmp(labelNeuron1, labelNeuron2), 2}{end, 4} = tnNeuron2;
    else 
        sortedNeurons{end+1, 1} = labelNeuron2; % otherwise create a new group
        sortedNeurons{end, end}{end+1, 1} = ratioNeuron2;
        sortedNeurons{end, end}{end, 2} = dateNeuron2;
        sortedNeurons{end, end}{end, 3} = nfNeuron2;
        sortedNeurons{end, end}{end, 4} = tnNeuron2;
    end
end

% Make a matrix of selected neurons
selectedNeurons = {'AFDL', 'AFDR', 'AIBL', 'AIBR', 'AIYL', 'AIYR', 'AIZL', 'AIZR', 'ALA',...
                  'ASEL', 'ASER', 'ASHL', 'ASHR', 'ASKL', 'ASKR', 'AVAL', 'AVAR', 'AVDL', 'AVDR',...
                  'AVEL', 'AVER', 'AVHL', 'AVHR', 'AWAL', 'AWAR', 'AWBL', 'AWBR', 'AWCL', 'AWCR',...
                  'BAGL', 'BAGR', 'RID', 'RIML', 'RIMR', 'RIS', 'RMED', 'RMEL', 'RMER', 'RMEV',...
                  'SAAVL', 'SAAVR', 'SMDDL', 'SMDDR', 'SMDVL', 'SMDVR', 'URXL', 'URXR'};
              
numNeurons = size(selectedNeurons, 2);
numTimepoints = size(sortedNeurons{1, 2}{1, 1}, 1);
numWorms = size(listFiles, 1);
numNeuronsLabeled = size(labelledNeurons, 1);

matrixNeurons = nan(numTimepoints, numNeurons, numWorms);

for ln = 1:numNeuronsLabeled
    snn = strcmp(labelledNeurons{ln, 1}, selectedNeurons);
    lnn = labelledNeurons{ln, 4};
    if any(snn)
        matrixNeurons(:, snn, lnn) = labelledNeurons{ln, 2};
    end
end
        
save([pathInput, '\', 'matrixNeurons.mat'], 'matrixNeurons');
save([pathInput, '\', 'selectedNeurons.mat'], 'selectedNeurons');



if flgMeanLR
    
    for cs = 1:size(sortedNeurons, 1)

        stamps = sortedNeurons{cs, 2}(:, 2);
        st = 1;
        while st < length(stamps)
            stampThisCell = sortedNeurons{cs, 2}{st, 2};
            flgMean = strcmp(stamps, stampThisCell);
            flgMean(1:st) = false;
            if any(flgMean)
                sortedNeurons{cs, 2}{st, 1} = mean(cat(2,...
                    sortedNeurons{cs, 2}{st, 1}, sortedNeurons{cs, 2}{flgMean, 1}), 2);
                sortedNeurons{cs, 2}(flgMean, :) = [];
            end
            stamps = sortedNeurons{cs, 2}(:, 2);
            st = st + 1;
        end
    end
end

% if flgModules
%     
%     for cs = 1:size(sortedNeurons, 1)
%         
%         stamps = sortedNeurons{cs, 2}(:, 2);
%         st = 1;
%         while st < length(stamps)
%             stampThisCell = sortedNeurons{cs, 2}{st, 2};
%             flgMean = strcmp(stamps, stampThisCell);
%             flgMean(1:st) = false;
%             if any(flgMean)
%                 sortedNeurons{cs, 2}{st, 1} = mean(cat(2,...
%                     sortedNeurons{cs, 2}{st, 1}, sortedNeurons{cs, 2}{flgMean, 1}), 2);
%                 sortedNeurons{cs, 2}(flgMean, :) = [];
%             end
%             stamps = sortedNeurons{cs, 2}(:, 2);
%             st = st + 1;
%         end
%     end
%     
% end


sortedNeurons = sortrows(sortedNeurons, 1);

warning('on', 'MATLAB:linearinter:noextrap');

save([pathInput, '\', 'sortedNeurons.mat'], 'sortedNeurons');
save([pathInput, '\', 'listFiles.mat'], 'listFiles');

scrollablePlots(pathInput);


