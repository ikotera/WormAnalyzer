function [neurons, n_list, handles] = trackAll(handles, states, hFunctions, imgRAM, neurons, n_list,...
    dimX, dimY, dimZ, valZ, dimT, dimTP, crop_size_r, crop_size_c, flgGUI, flgW, handlesW, tW, pathFolder)

% function [neurons, n_list, handles] = trackAll(handles, states, hFunctions, imgRAM, neurons, n_list,...
%     dimX, dimY, dimZ, valZ, dimT, dimTP, crop_size_r, crop_size_c, modeImageTrack,...
%     ND, pathICE, imgMap, flgGUI, flgW, handlesW, tW)

% Added 140130
if flgGUI && states.forAllZ
    zarray = 1:dimZ;    % Track points for all z if checkbox is checked on GUI mode
elseif ~flgGUI
    zarray = 1:dimZ;    % Track points for all z if it's non-GUI mode
else
    zarray = valZ;      % Track points for selected z in all other cases
end
if ~exist('flgW', 'var')
    flgW = false;
end

if flgGUI
    if states.registerBeforeTrack
        hFunctions.registerImagesGateway();
    end
    progressBar(flgGUI, handles, 'initiate', 'Initializing CPU cores');
end
if flgW
    updateElapsedTime(handlesW, tW);
    set(handlesW.textMessage,'String', 'Initializing CPU cores');
    drawnow;
end


% stack = zeros(dimY, dimX, dimZ, 2, 'uint16');
for ch = 1:2
    stack{ch} = reshape(imgRAM{ch}, dimY, dimX, dimZ, dimTP);
end


progressBar(flgGUI, handles, 'initiate', 'Tracking all the neurons...');

if flgW
    updateElapsedTime(handlesW, tW);
    set(handlesW.textMessage,'String', 'Tracking all the neurons...');
    drawnow;
end

fr_fin = dimT/dimZ; % Last time point

for z = zarray  % Loop through selected z-levels
    checkForDuplicatedFlags(pathFolder);
    startZ = tic;
    
    ndata = neurons{z}; 	% Neurons in this z-level
    dimN = numel(ndata);    % Number of neurons
    
    % Preallocation for parfor
    pos = zeros(dimT/dimZ, 2, dimN);
%     dx = zeros(crop_size_r, crop_size_c, dimT/dimZ, dimN);
%     dy = zeros(crop_size_r, crop_size_c, dimT/dimZ, dimN);
    segm_crop = false(crop_size_r, crop_size_c, dimT/dimZ, dimN);
    segm_crop_pos = nan(dimT/dimZ, 4, dimN);
    int_ratio = zeros(dimT/dimZ, dimN);
    int_g = zeros(dimT/dimZ, dimN);
    int_r = zeros(dimT/dimZ, dimN);
    for ch = 1:2
        sliceZ{ch} = squeeze( stack{ch}(:, :, z, :) );
    end
    
    % Loop through all seeds in PARALLEL
    parfor n = 1:dimN
        tN = tic;
        neuron = ndata{n};
        fr_init = neuron.init_fr;
        r_init = round(neuron.pos(fr_init,1));
        c_init = round(neuron.pos(fr_init,2));

%         [pos_sn, segm_crop_sn, int_ratio_sn, int_g_sn, int_r_sn, segm_crop_pos_sn, dx_sn, dy_sn] =...
%             trackNeuron(sliceZ, dimT, dimZ, dimY, dimX, ND, crop_size_r, crop_size_c,...
%             pathICE{1}, pathICE{2}, imgMap{1}, imgMap{2},...
%             r_init, c_init, fr_init, fr_fin, z, modeImageTrack,[],[]);
        
        
        [pos_sn, segm_crop_sn, int_ratio_sn, int_g_sn, int_r_sn, segm_crop_pos_sn, ~, ~] = trackNeuron(...
        sliceZ, dimT, dimZ, dimY, dimX, crop_size_r, crop_size_c, r_init, c_init, fr_init, fr_fin, ...
        [], []);

        pos(:, :, n) = pos_sn;
%         dx(:, :, :, n) = dx_sn;
%         dy(:, :, :, n) = dy_sn;
        segm_crop(:, :, :, n) = segm_crop_sn;
        segm_crop_pos(:, :, n) = segm_crop_pos_sn;
        int_ratio(:, n) = int_ratio_sn;
        int_g(:, n) = int_g_sn;
        int_r(:, n) = int_r_sn;
        
        prt('%2.4f', 'Tracking of', neuron.name, ':', toc(tN), 'seconds.');
    end
    
    % Check if the point converged to a pre-existing point; Added 140130

    for n = 1:dimN
        tC = tic;
        converged = 0;
        % 0 = No convergence
        % 1 = Current point converges into a previous one
        % 2 = Previous point converges to the current one
        prevpt = 0; % Previous point if converged == 2; Added 140306 by Jimmy
        
        for j = 1:n-1
            if neurons{z}{j}.pos(end, 1:2) == pos(end,:,n)
                % Added 140306 by Jimmy
                var1 = var(neurons{z}{j}.pos(:,1:2),0,1);
                var2 = var(pos(:,:,n),0,1);
                
                % Finding the common coordinates
                %compconv = neurons{z}{j}.pos(:,1:2) == pos(:,:,n);
                %compconv = compconv(:,1) & compconv(:,2);
                %convtime = find(compconv, 1);
                
                if sum(var1) <= sum(var2)   % previous point more stable
                    converged = 1;
                elseif sum(var1) > sum(var2)    % current point more stable
                    converged = 2;
                end
                prevpt = j;
                break;
            end
        end
        
        if converged == 0   % Assign data
            neurons{z}{n}.pos = pos(:, :, n);
            neurons{z}{n}.segm = segm_crop(:, :, :, n);
            neurons{z}{n}.segm_crop_pos = segm_crop_pos(:, :, n);
            neurons{z}{n}.int_ratio = int_ratio(:, n);
            neurons{z}{n}.int_g = int_g(:, n);
            neurons{z}{n}.int_r = int_r(:, n);
            
        else
            % Retrack the merged point
            if ~isempty(neurons{z})
                if converged == 1   % Added 140306 by Jimmy
                    % Retrack new point
                    fr_init = ndata{n}.init_fr;
                    r_initb = round(pos(fr_init,1,n));
                    c_initb = round(pos(fr_init,2,n));
%                     
%                     [pos_bn, segm_crop_bn, int_ratio_bn, int_g_bn, int_r_bn, segm_crop_pos_bn, dx_bn, dy_bn] =...
%                         trackNeuron(sliceZ, dimT, dimZ, dimY, dimX, ND, crop_size_r, crop_size_c,...
%                         pathICE{1}, pathICE{2}, imgMap{1}, imgMap{2},...
%                         r_initb, c_initb, fr_init, fr_fin, z, modeImageTrack, ...
%                         segm_crop(:,:,:,prevpt), segm_crop_pos(:,:,prevpt));
                    
                    [pos_bn, segm_crop_bn, int_ratio_bn, int_g_bn, int_r_bn, segm_crop_pos_bn, ~, ~] = trackNeuron(...
                        sliceZ, dimT, dimZ, dimY, dimX, crop_size_r, crop_size_c, r_initb, c_initb, fr_init, fr_fin, ...
                        segm_crop(:,:,:,prevpt), segm_crop_pos(:,:,prevpt));
                    
                    
                    % Update data
                    pos(:,:,n) = pos_bn;
                    segm_crop(:, :, :, n) = segm_crop_bn;
                    segm_crop_pos(:, :, n) = segm_crop_pos_bn;
                    int_ratio(:, n) = int_ratio_bn;
                    int_g(:, n) = int_g_bn;
                    int_r(:, n) = int_r_bn;
                    
                    % Assign data
                    neurons{z}{n}.pos = pos(:, :, n);
                    neurons{z}{n}.segm = segm_crop(:, :, :, n);
                    neurons{z}{n}.segm_crop_pos = segm_crop_pos(:, :, n);
                    neurons{z}{n}.int_ratio = int_ratio(:, n);
                    neurons{z}{n}.int_g = int_g(:, n);
                    neurons{z}{n}.int_r = int_r(:, n);
                elseif converged == 2
                    % Assign new point
                    neurons{z}{n}.pos = pos(:, :, n);
                    neurons{z}{n}.segm = segm_crop(:, :, :, n);
                    neurons{z}{n}.segm_crop_pos = segm_crop_pos(:, :, n);
                    neurons{z}{n}.int_ratio = int_ratio(:, n);
                    neurons{z}{n}.int_g = int_g(:, n);
                    neurons{z}{n}.int_r = int_r(:, n);
                    
                    % Retrack old point
                    fr_init = ndata{prevpt}.init_fr;
                    r_initb = round(pos(fr_init,1,prevpt));
                    c_initb = round(pos(fr_init,2,prevpt));
                    
%                     [pos_bn, segm_crop_bn, int_ratio_bn, int_g_bn, int_r_bn, segm_crop_pos_bn, dx_bn, dy_bn] =...
%                         trackNeuron(sliceZ, dimT, dimZ, dimY, dimX, ND, crop_size_r, crop_size_c,...
%                         pathICE{1}, pathICE{2}, imgMap{1}, imgMap{2},...
%                         r_initb, c_initb, fr_init, fr_fin, z, modeImageTrack, ...
%                         segm_crop(:, :, :, n), segm_crop_pos(:, :, n));
                    
                    [pos_bn, segm_crop_bn, int_ratio_bn, int_g_bn, int_r_bn, segm_crop_pos_bn, ~, ~] = trackNeuron(...
                        sliceZ, dimT, dimZ, dimY, dimX, crop_size_r, crop_size_c, r_initb, c_initb, fr_init, fr_fin, ...
                        segm_crop(:, :, :, n), segm_crop_pos(:, :, n));
                    
                    % Update data
                    pos(:,:,prevpt) = pos_bn;
                    segm_crop(:, :, :, prevpt) = segm_crop_bn;
                    segm_crop_pos(:, :, prevpt) = segm_crop_pos_bn;
                    int_ratio(:, prevpt) = int_ratio_bn;
                    int_g(:, prevpt) = int_g_bn;
                    int_r(:, prevpt) = int_r_bn;
                    
                    % Assign data
                    neurons{z}{prevpt}.pos = pos(:, :, prevpt);
                    neurons{z}{prevpt}.segm = segm_crop(:, :, :, prevpt);
                    neurons{z}{prevpt}.segm_crop_pos = segm_crop_pos(:, :, prevpt);
                    neurons{z}{prevpt}.int_ratio = int_ratio(:, prevpt);
                    neurons{z}{prevpt}.int_g = int_g(:, prevpt);
                    neurons{z}{prevpt}.int_r = int_r(:, prevpt);
                end
                
                if flgGUI
                    if ~numel(n_list{z})
                        n_list{z} = []; % Preserve cell structure
                    end
                    index = get(handles.listN, 'Value');
                    hFunctions.updateList;
                    set(handles.listN, 'Value', max(1,min(index, numel(n_list{z}))));
%                     set(handles.selectNeuron1,'Value', max(min(index, numel(n_list{z})),1));
%                     set(handles.selectNeuron2,'Value', max(min(index, numel(n_list{z})),1));
                end
            end
        end
        prt('%2.4f', 'Convergence of neuron', n, ':', toc(tC), 'seconds.');
    end
    
    
    endZ = toc(startZ);

    progressBar(flgGUI, handles, 'iterate', [], z, dimZ);

    if flgW
        updateElapsedTime(handlesW, tW);
        set(handlesW.textIteration,'String', ['z = ', num2str(z), ' | ', num2str(endZ), ' seconds.']);
        drawnow;
    end
%     prt(flgW, num2str(tW), ['z = ', num2str(z), ' | ', num2str(endZ), ' seconds.']);
    prt('z=', num2str(z), ':', num2str(endZ), 'seconds.');
end

progressBar(flgGUI, handles, 'terminate', 'Finished tracking.');

delete(gcp('nocreate')); % Shutdown parallel pool

if flgGUI
    hFunctions.initializeOverlays(neurons);
    hFunctions.displayImage();
end
end

