function neurons = trackSel3D(handles, hFunctions, neurons, dimX, dimY, dimZ, dimT, valZ,...
    ND, crop_size_r, crop_size_c, crop_size_z, pathICE, imgMap, modeImageTrack)

if get(handles.checkRegister, 'Value')
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
z_init = round(neuron.pos(fr_init,3));

[pos, segm_crop, int_ratio, segm_crop_pos, ~, ~] =...
    trackNeuron3D(dimT, dimZ, dimY, dimX, ND, crop_size_r, crop_size_c,...
    crop_size_z, pathICE{1}, pathICE{2}, imgMap{1}, imgMap{2},...
    r_init, c_init, z_init, fr_init, fr_fin, modeImageTrack);

neurons{z_init}{index}.pos = pos;
neurons{z_init}{index}.segm = segm_crop;
neurons{z_init}{index}.int_ratio = int_ratio;
neurons{z_init}{index}.segm_crop_pos = segm_crop_pos;
endN = toc(startN);
fprintf([neuron.name, ': ', num2str(endN), ' seconds.\n']);

hFunctions.initializeOverlays(neurons);
hFunctions.displayImage();

end