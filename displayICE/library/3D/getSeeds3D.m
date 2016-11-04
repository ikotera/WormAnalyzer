function [neurons, n_list] = getSeeds3D(handles, hFunctions, neurons, n_list,...
    dimX, dimY, dimZ, dimT, valT, pathICE, ND, modeImage, imgRAM, imgMap, flgGUI)

progressBar(handles, 'initiate', 'Calculating initial seeds...');

startF = tic;

img = zeros(dimY,dimX,dimZ);

for z = 1:dimZ
    img(:,:,z) = readImage(valT, dimT, z, dimZ, pathICE{1}, ND, modeImage, imgRAM{1}, imgMap);
end

[R, C, Z] = local_max_gvf3D(uint16(img));

numSeeds = numel(R);

for i = 1:numSeeds
    pos = zeros(dimT/dimZ,3);
    pos(valT,1) = R(i);
    pos(valT,2) = C(i);
    pos(valT,3) = Z(i);
    
    segm = []; % 130827
    segm_crop_pos = [];
    int_ratio = zeros(1, dimT/dimZ);
    
    neuron = struct(                        ...
    'name',         ['neuron', num2str(i)], ...
    'z',            z,                      ...
    'init_fr',      valT,                   ...
    'pos',          pos,                    ...
    'segm',         segm,                   ...
    'segm_crop_pos', segm_crop_pos,         ...
    'int_ratio',    int_ratio);
    
    num = numel(neurons{Z(i)}) + 1;

    neurons{Z(i)}{num} = neuron;
    n_list{Z(i)}{num} = neuron.name;
    
    progressBar(handles, 'iterate', [], i, numSeeds);
end
    
endF = toc(startF);
    
fprintf(['number of neurons=',num2str(numSeeds), ': ', num2str(endF), ' seconds.\n'])

progressBar(handles, 'terminate', 'Finished seed calculation.');
hFunctions.updateList();
set(handles.listN, 'Value', 1);

hFunctions.initializeOverlays(neurons);
hFunctions.updateList(n_list);
hFunctions.displayImage();
hFunctions.enableTracking();

end