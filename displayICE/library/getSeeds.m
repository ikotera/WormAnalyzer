function [neurons, n_list] = getSeeds(handles, states, hFunctions, neurons, n_list,...
    dimZ, dimT, valZ, valT, pathICE, ND, filters, flgGUI, flgWI, handlesWI, tWI, threshSeed)

if flgGUI && states.forAllZ
    zarray = 1:dimZ;    % Get seeds for all z if checkbox is checked on GUI mode
elseif ~flgGUI
    zarray = 1:dimZ;    % Get seeds for all z if it's non-GUI mode
else
    zarray = valZ;      % Get seeds for selected z in all other cases
end
if ~exist('flgW', 'var')
    flgWI = false;
end

if flgGUI
    progressBar(flgGUI, handles, 'initiate', 'Calculating initial seeds...');
else
    prt('Calculating initial seeds...');
end
if flgWI
    updateElapsedTime(handlesWI, tWI);
    set(handlesWI.textMessage,'String', 'Calculating initial seeds...');
    drawnow;
end

% for z = zarray
%     startZ = tic;
%     
%     img(:, :, z) = readImage(valT, dimT, z, dimZ, pathICE{1}, ND, modeImage, imgRAM{1}, imgMap);
% end

% startZ = tic;
stack = openICE(ND{1}(valT, 1), dimZ, pathICE{1}); % Get an image stack for the selected time point

stack = filterImage(stack, filters);

for z = zarray
    startZ = tic;
%     img = readImage(valT, dimT, z, dimZ, pathICE{1}, ND, modeImage, imgRAM{1}, imgMap);

    [R, C] = local_max_gvf(stack(:, :, z), filters, threshSeed);
    
    numSeeds = numel(R);
    
    if numSeeds > 300 % Too many seeds usually means the image is too noisy to process properly
        numSeeds = 0;
    end
    
    neurons{z} = cell(1, numSeeds);
    n_list{z} = cell(numSeeds, 1);
    
    for i = 1:numSeeds
        pos = zeros(dimT/dimZ, 2);
        pos(valT, 1) = R(i);
        pos(valT, 2) = C(i);
        
        segm = []; % 130827
        segm_crop_pos = [];
        int_ratio = zeros(dimT/dimZ, 1);
        int_g = zeros(dimT/dimZ, 1);
        int_r = zeros(dimT/dimZ, 1);
        
        neuron = struct(                            ...
            'name',         ['neuron', num2str(i)], ...
            'z',            z,                      ...
            'init_fr',      valT,                   ...
            'pos',          pos,                    ...
            'segm',         segm,                   ...
            'segm_crop_pos', segm_crop_pos,         ...
            'int_ratio',    int_ratio,              ...
            'int_g',        int_g,                  ...
            'int_r',        int_r);
        
        neurons{z}{i} = neuron;
        n_list{z}{i} = neuron.name;
    end
    
    endZ = toc(startZ);
    
    if flgGUI
        progressBar(flgGUI, handles, 'iterate', [], z, numel(zarray));
    end
    
    prt('z=', z, ':', endZ, 'seconds.');
    if flgWI
        updateElapsedTime(handlesWI, tWI);
        set(handlesWI.textIteration,'String', ['z= ', num2str(z), ' | ', num2str(endZ), ' seconds.']);
        drawnow;
    end
end

if flgGUI
    progressBar(flgGUI, handles, 'terminate', 'Finished seed calculation.');
    hFunctions.updateList();
    set(handles.listN, 'Value', 1);
    
    hFunctions.initializeOverlays(neurons);
    hFunctions.updateList(n_list);
    hFunctions.displayImage();
    hFunctions.enableTracking();
else
    prt('Finished seed calculation.');
end

end