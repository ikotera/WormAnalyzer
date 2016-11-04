    function registerImagesSubpixel(handles, hFunctions, pathICE,...
        imgRAM, modeImage, sVar, dimX, dimY, dimZ, dimT)
        
        flgGPU = get(handles.checkGPU, 'value');
        if flgGPU && ~isGpuAvailable
            set(handles.checkGPU, 'value', 0);
            flgGPU = 0;
            prt('CUDA-capable GPU card not available');
        end
    
        % Load images to RAM if not already
        switch modeImage
            case 'RAM'
            otherwise
                set(handles.selectModeImage, 'Value', 2);
                hFunctions.changeModeImage([], [], true)
                return
        end
        
        % Check if the images are already registered
        [path, file, ext] = fileparts(pathICE{1});
        pathICEnew{1} = [path, '\', file(1:5), 'R', file(6:end), ext];
        file(5) = '2';
        pathICEnew{2} = [path, '\', file(1:5), 'R', file(6:end), ext];              
        if strcmp(file(6), 'R') % If already registered
            choice = questdlg(...
                'Images seem to be registered. Do you want to re-register images?', ...
                'Registration Confirmation', ...
                'Yes', 'No', 'No');
            switch choice
                case 'No'
                    return
            end
        end        

        % Get the first stack as template
        stackTemplate = zeros(dimY, dimX, dimZ, 2, 'uint16');
        for ch = 1 : 2
            stackTemplate(:, :, :, ch) = imgRAM{ch}(:, :, 1:dimZ); 
        end
        
startR = tic;

        handles.progressBar.setVisible(true);
        handles.movingBar.setVisible(true);
        
        % Calculate images shifts at subpixel resolution
        for ch = 1:2
            [~, f{ch}, e{ch}] = fileparts(pathICE{ch}); %#ok<AGROW>
            nameFile{ch} = [f{ch}, e{ch}]; %#ok<AGROW>
        end
        shifts = nan(dimT, 4, 2);

        if flgGPU
            progressBar(handles, 'initiate', 'Calculating image shifts on GPU ...');
            for ch = 1:1
                for fr = dimZ+1 : dimT
                    shifts(fr, :, ch) = dftregistrationGPU...
                        (fft2(gpuArray(stackTemplate(:, :, sVar.infoND(fr, 2), ch))),...
                        fft2(gpuArray(imgRAM{ch}(:, :, fr))), 10);
                    progressBar(handles, 'iterate', [], fr, (dimT));
                end
            end
            
        else
            progressBar(handles, 'initiate', 'Calculating image shifts on CPU ...');
            for ch = 1:1
                for fr = dimZ+1 : dimT
                    shifts(fr, :, ch) = dftregistration...
                        (fft2((stackTemplate(:, :, sVar.infoND(fr, 2), ch))),...
                        fft2((imgRAM{ch}(:, :, fr))), 10);
                    progressBar(handles, 'iterate', [], fr, (dimT));
                end
            end
        end
     
prt('Shift calculation ... done,', toc(startR), 's');        
startR = tic;        
        
        shiftedStack = nan(dimY, dimX, dimT, 2);
        
        for ch = 1:2
            shiftedStack(:, :, 1:dimZ, ch) = imgRAM{ch}(:, :, 1:dimZ);
        end
        
        if flgGPU
            % Shift the images
            for ch = 1:2
                progressBar(handles, 'initiate', ['Registering ',  nameFile{ch}, ' on GPU ...']);
                for fr = dimZ+1 : dimT
                    shiftedStack(:, :, fr, ch) = shiftImageSubpixelGPU(gpuArray...
                        (double(imgRAM{ch}(:, :, fr))), shifts(fr, 3, 1), shifts(fr, 4, 1));
                    progressBar(handles, 'iterate', [], fr, (dimT));
                end
            end
            
        else
            % Shift the images
            for ch = 1:2
                progressBar(handles, 'initiate', ['Registering ',  nameFile{ch}, ' on CPU ...']);
                for fr = dimZ+1 : dimT
                    shiftedStack(:, :, fr, ch) =...
                        shiftImageSubpixel...
                        (double(imgRAM{ch}(:, :, fr)), shifts(fr, 3, 1), shifts(fr, 4, 1));
                    progressBar(handles, 'iterate', [], fr, (dimT));
                end
            end
        end
     
prt('Image shifting ... done,', toc(startR), 's');               
startR = tic;
        for ch = 1:2
            [~, f{ch}, e{ch}] = fileparts(pathICEnew{ch}); %#ok<AGROW>
            nameFile{ch} = [f{ch}, e{ch}]; %#ok<AGROW>
        end

        % Write the shifted images to ICE files
        progressBar(handles, 'initiate', []);
        for ch = 1 : 2
            progressBar(handles, 'iterate', ['Saving ',  nameFile{ch}, ' to Disk ...'], ch, 2);
            ln = reshape(shiftedStack(:, :, :, ch), dimY * dimX * dimT, 1);
            fd = writeICE(nan, nan, pathICEnew{ch}, nan, '');
            writeICE(fd, ln);
            fclose(fd);
            
        end
         
prt('Saving to disk ... done,', toc(startR), 's');       

        % Copy headers
        copyHeaderICE(pathICE{1}, pathICEnew{1});
        copyHeaderICE(pathICE{2}, pathICEnew{2});
        
        % Finalize progress bar and whatnot
        handles.movingBar.setVisible(false);
        handles.statusBar.setText('Finished image registration ...');
        
        % Re-initialize GUI with registered images
        pathICE{1} = pathICEnew{1};
        pathICE{2} = pathICEnew{2};
        hFunctions.initialize(pathICE{1});
        hFunctions.displayImage();
        
    end
    
    