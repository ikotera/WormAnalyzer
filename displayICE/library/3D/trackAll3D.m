    function [neurons, n_list, handles] = trackAll3D(handles, hFunctions, neurons, n_list,...
        dimX, dimY, dimZ, dimT, crop_size_r, crop_size_c, crop_size_z, modeImageTrack,...
        ND, pathICE, imgMap, poolsize, flgGUI)
    
        if get(handles.checkRegister, 'Value')
            hFunctions.registerImagesGateway();
        end
        
        % Start matlabpool if not previously started
        progressBar(handles, 'initiate', 'Initializing CPU cores');
        if(matlabpool('size') <= 0);
            try
                matlabpool(poolsize)
            catch E
                if (strcmp(E.identifier, 'distcomp:interactive:OpenConnection'))
                    matlabpool close force local
                    matlabpool(poolsize)
                else
                    throw(E);
                end
            end
        end
        
%         profile on
        startT = tic;
        progressBar(handles, 'initiate', 'Tracking all the neurons...');
        
        fr_fin = dimT/dimZ; % Last time point
        
        for z = 1:dimZ  % Loop through all z-levels
            startZ = tic;
            
            ndata = neurons{z}; 	% Neurons in this z-level
            dimN = numel(ndata);    % Number of neurons
            
            % Preallocation for parfor
            pos = zeros(dimT/dimZ, 3, dimN);
            dx = zeros(crop_size_r, crop_size_c, crop_size_z, dimT/dimZ, dimN);
            dy = zeros(crop_size_r, crop_size_c, crop_size_z, dimT/dimZ, dimN);
            segm_crop = false(crop_size_r, crop_size_c, crop_size_z, dimT/dimZ, dimN);
            segm_crop_pos = nan(dimT/dimZ, 6, dimN);
            int_ratio = zeros(1, dimT/dimZ, dimN);
            
            % Loop through all seeds
            parfor n = 1:dimN
                startN = tic;
                neuron = ndata{n};
                fr_init = neuron.init_fr;
                r_init = round(neuron.pos(fr_init,1));
                c_init = round(neuron.pos(fr_init,2));
                z_init = round(neuron.pos(fr_init,3));
                
                [pos_sn, segm_crop_sn, int_ratio_sn, segm_crop_pos_sn, dx_sn, dy_sn, dz_sn] =...
                    trackNeuron3D(dimT, dimZ, dimY, dimX, ND, crop_size_r, crop_size_c,...
                    crop_size_z, pathICE{1}, pathICE{2}, imgMap{1}, imgMap{2},...
                    r_init, c_init, z_init, fr_init, fr_fin, modeImageTrack, [], []);
                
                pos(:, :, n) = pos_sn;
                dx(:, :, :, :, n) = dx_sn;
                dy(:, :, :, :, n) = dy_sn;
                segm_crop(:, :, :, :, n) = segm_crop_sn;
                segm_crop_pos(:, :, n) = segm_crop_pos_sn;
                int_ratio(1, :, n) = int_ratio_sn;
                
                endN = toc(startN);
                fprintf([neuron.name, ': ', num2str(endN), ' seconds.\n'])
            end
            
            % Check if the point converged to a pre-existing point; Added 140130
            n = 1;
            
            while n <= numel(neurons{z})
                converged = 0;
                % 0 = No convergence
                % 1 = Current point converges into a previous one
                % 2 = Previous point converges to the current one
                prevpt = 0; % Previous point if converged == 2; Added 140306 by Jimmy
                
                for j = 1:n-1
                    if neurons{z}{j}.pos(end, 1:3) == pos(end,:,n)
                        var1 = var(neurons{z}{j}.pos(:,1:3), 0, 1);
                        var2 = var(pos(:,:,n), 0, 1);
                        
                        if sum(var1) <= sum(var2)   % previous point more stable
                            converged = 1;
                        elseif sum(var1) > sum(var2)    % current point more stable
                            prevpt = j;
                            converged = 2;
                        end
                        break;
                    end
                end
                
                if ~converged   % Assign data
                    neurons{z}{n}.pos = pos(:, :, n);
                    neurons{z}{n}.segm = segm_crop(:, :, :, :, n);
                    neurons{z}{n}.segm_crop_pos = segm_crop_pos(:, :, n);
                    neurons{z}{n}.int_ratio = int_ratio(:, :, n);
                else
                    % Delete the converged point (adapted from the function delNeuron)
                    if ~isempty(neurons{z})
                        if converged == 1 % Added 140306 by Jimmy
                            % Retrack new point
                            fr_init = ndata{n}.init_fr;
                            r_initb = round(pos(fr_init,1,n));
                            c_initb = round(pos(fr_init,2,n));
                            z_initb = round(pos(fr_init,3,n));
                            
                            [pos_bn, segm_crop_bn, int_ratio_bn, segm_crop_pos_bn, dx_bn, dy_bn, dz_bn] =...
                                trackNeuron3D(dimT, dimZ, dimY, dimX, ND, crop_size_r, crop_size_c,...
                                crop_size_z, pathICE{1}, pathICE{2}, imgMap{1}, imgMap{2},...
                                r_initb, c_initb, z_initb, fr_init, fr_fin, modeImageTrack, ...
                                segm_crop(:,:,:,:,prevpt), segm_crop_pos(:,:,prevpt));
                            
                            % Update data
                            pos(:,:,n) = pos_bn;
                            segm_crop(:, :, :, :, n) = segm_crop_bn;
                            segm_crop_pos(:, :, n) = segm_crop_pos_bn;
                            int_ratio(:, :, n) = int_ratio_bn;
                            
                            % Assign data
                            neurons{z}{n}.pos = pos(:, :, n);
                            neurons{z}{n}.segm = segm_crop(:, :, :, :, n);
                            neurons{z}{n}.segm_crop_pos = segm_crop_pos(:, :, n);
                            neurons{z}{n}.int_ratio = int_ratio(:, :, n);
                        elseif converged == 2                            
                            % Assign new point
                            neurons{z}{n}.pos = pos(:, :, n);
                            neurons{z}{n}.segm = segm_crop(:, :, :, :, n);
                            neurons{z}{n}.segm_crop_pos = segm_crop_pos(:, :, n);
                            neurons{z}{n}.int_ratio = int_ratio(:, :, n);
                            
                            % Retrack new point
                            fr_init = ndata{prevpt}.init_fr;
                            r_initb = round(pos(fr_init,1,prevpt));
                            c_initb = round(pos(fr_init,2,prevpt));
                            z_initb = round(pos(fr_init,3,prevpt));
                            
                            [pos_bn, segm_crop_bn, int_ratio_bn, segm_crop_pos_bn, dx_bn, dy_bn, dz_bn] =...
                                trackNeuron3D(dimT, dimZ, dimY, dimX, ND, crop_size_r, crop_size_c,...
                                crop_size_z, pathICE{1}, pathICE{2}, imgMap{1}, imgMap{2},...
                                r_initb, c_initb, z_initb, fr_init, fr_fin, modeImageTrack, ...
                                segm_crop(:,:,:,:,n), segm_crop_pos(:,:,n));
                            
                            % Update data
                            pos(:,:,prevpt) = pos_bn;
                            segm_crop(:, :, :, :, prevpt) = segm_crop_bn;
                            segm_crop_pos(:, :, prevpt) = segm_crop_pos_bn;
                            int_ratio(:, :, prevpt) = int_ratio_bn;
                            
                            % Assign data
                            neurons{z}{prevpt}.pos = pos(:, :, prevpt);
                            neurons{z}{prevpt}.segm = segm_crop(:, :, :, :, prevpt);
                            neurons{z}{prevpt}.segm_crop_pos = segm_crop_pos(:, :, prevpt);
                            neurons{z}{prevpt}.int_ratio = int_ratio(:, :, prevpt);
                        end
                        
                        if ~numel(n_list{z})
                            n_list{z} = []; % Preserve cell structure
                        end
                        index = get(handles.listN, 'Value');
                        hFunctions.updateList;
                        set(handles.listN, 'Value', max(1,min(index, numel(n_list{z}))));
                        set(handles.selectNeuron1, 'Value', max(min(index, numel(n_list{z})),1));
                        set(handles.selectNeuron2, 'Value', max(min(index, numel(n_list{z})),1));
                    end
                end
                
                n = n + 1;  % Advance counter
            end

            progressBar(handles, 'iterate', [], z, dimZ);
        endZ = toc(startZ);
            fprintf(['z=', num2str(z), ': ', num2str(endZ), ' seconds.\n'])
        end

        progressBar(handles, 'terminate', 'Finished tracking.');
        
        endT = toc(startT);
        fprintf(['Total: ', num2str(endT), ' seconds.\n'])
        
        hFunctions.initializeOverlays(neurons);
        hFunctions.displayImage();
        
    end
    
    