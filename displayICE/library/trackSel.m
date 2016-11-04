function neurons = trackSel(handles, states, hFunctions, neurons, dimX, dimY, dimZ, dimT, valZ,...
    ND, crop_size_r, crop_size_c, pathICE, imgMap, modeImageTrack)

if states.registerBeforeTrack
    hFunctions.registerImagesGateway();
end

startN = tic;

index = get(handles.listN, 'Value');
ndata = neurons{valZ};
neuron = ndata{index};
fr_init = neuron.init_fr;
fr_fin = dimT/dimZ;
r_init = round(neuron.pos(fr_init,1));
c_init = round(neuron.pos(fr_init,2));

[pos, segm_crop, int_ratio, segm_crop_pos, ~, ~] =...
    trackNeuron(dimT, dimZ, dimY, dimX, ND, crop_size_r, crop_size_c,...
    pathICE{1}, pathICE{2}, imgMap{1}, imgMap{2},...
    r_init, c_init, fr_init, fr_fin, valZ, modeImageTrack, [], []);

neurons{valZ}{index}.pos = pos;
neurons{valZ}{index}.segm = segm_crop;
neurons{valZ}{index}.int_ratio = int_ratio;
neurons{valZ}{index}.segm_crop_pos = segm_crop_pos;
endN = toc(startN);
fprintf([neuron.name, ': ', num2str(endN), ' seconds.\n']);

hFunctions.initializeOverlays(neurons);
hFunctions.displayImage();

end