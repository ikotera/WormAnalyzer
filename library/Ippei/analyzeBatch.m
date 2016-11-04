function s = analyzeBatch(pathIce, flgDeconvolution, flgRegistration, flgTracking, flgGui, flgSave, handles)

% -Dependendies: Miji.m, rdir.m, prt.m, deconvij.m, openICE, readHeaderICE, writeICE.m,
% copyHeaderICE.m, checkPathType.m, isGpuAvailable

%% Declare Public Variables
threshSizeFile = 1e+9; % If the size of ICE file exceeds this, then chunk it
flgGpu = 0; listIce = []; channelNum = [];
fdr = []; fdm = []; namePath = []; nameFileNew = []; nameFileMax = [];
dimT= []; dimZ = []; dimCh = []; dimChTp = []; dimTP = []; shifts = [];
tpStart = []; stackMPrev = []; msg = [];

%% Initialization
parseInputs;
manageFiles;

s.threshSeed = 80;
s.numGpuErr = 0;
s.tDecon = 0;
s.tReg = 0;
s.tTrack = 0;
s.tLoad = 0;
s.tSave = 0;
s.tWhole = tic;

initialize;

%% Batch Analysis
for nif = 1:numIceFiles
    
    prepareForAnalysis;
    checkForDuplicatedFlags(namePath);
    
    for chn = 1:numChunks + (remCh>0)
        
        tI = tic;
        updateChunkIndeces;
        prt('Loading:', nameFile);
        stack = loadICE(frStart, (frEnd - frStart + 1), fd, dimX, dimY);
        s.tLoad = s.tLoad + toc(tI);
        
        tD = tic;
        if flgDeconvolution
            stack = deconvolveImages(stack);
        else
            stack = reshape(stack, dimY, dimX, dimZ, dimChTp);
        end
        s.tDecon = s.tDecon + toc(tD);
        
        stackMip = createMip(stack);
        
        tR = tic;
        if flgRegistration
            [stack, stackMip] = registerImages(stack, stackMip);
        end
        s.tReg = s.tReg + toc(tR);

        if flgSave
            saveIce(stack, stackMip);
        end
    end
    finalizeIce;
    
end

s.tTrack = tic;
trackNuclei;
s.tTrack = toc(s.tTrack);

%% Finalization
finalizeBatch;

%% Nested Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function parseInputs
        if ~exist('flgDeconvolution', 'var')
            flgDeconvolution = 1;
        end
        if ~exist('flgRegistration', 'var')
            flgRegistration = 1;
        end
        if ~exist('flgTracking', 'var')
            flgTracking = 1;
        end
        if ~exist('flgGui', 'var')
            flgGui = false;
        end
        if ~exist('handles', 'var')
            handles = nan;
        end
        
        if isGpuAvailable
            flgGpu = 1;
        else
            prt('CUDA-capable GPU card not available');
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function manageFiles
        if ~exist('pathIce', 'var')
            % Prompt the user to choose a file
            pathIce = uigetdir(...
                'C:\', 'Select a Folder to Analyze');
            if pathIce == 0
                return;
            end
        end
        
        % Get a list of ice files in the folder and subfolders
        listIce = rdir([pathIce, '\**\*.ice']);
        numIceFiles = numel(listIce);
        fdel = false(numIceFiles, 1);
        for l = 1:numIceFiles
            [~, nm, ~] = fileparts(listIce(l).name); % name of the ice file
            if ~strcmp(nm(6), '_') % if the file name has infix after Img-N such as 'R'
                fdel(l) = true; % raise a delete flag
            end
        end
        listIce(fdel) = []; % remove the file name
        numIceFiles = numel(listIce);
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function initialize
        if flgDeconvolution
            % Clear all dynamic java paths
            djp = javaclasspath('-dynamic');
            if ~isempty(djp)
                javarmpath(djp{:});
            end
            
            if flgGui
                updateElapsedTime(handles, s.tWhole);
                set(handles.textProcess, 'String', 'Initialization');
                set(handles.textMessage,'String', 'Connecting to ImageJ...');
                drawnow;
            end
            Miji(false);
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function prepareForAnalysis
        if flgGui
            updateElapsedTime(handles, s.tWhole);
            drawnow;
        end
        
        [namePath, nF, nE] = fileparts(listIce(nif).name);
        nameFile = [nF, nE];
        channelNum = nameFile(5); % get channel number (ie, 1, 2, 3, or 4)
        nameFileNew = [nF(1:5), 'RD', nF(6:end), nE];
        nameFileMax = [nF(1:5), 'MX', nF(6:end), nE];
        
        if flgGui
            set(handles.textFile,'String', nameFile);
            drawnow;
        end
        prt('Processing files in', namePath);
        
        % Header info
        Str = readHeaderICE([namePath, '\', nameFile]);
        dimX = Str.dimX;
        dimY = Str.dimY;
        dimT = Str.dimT;
        dimZ = Str.dimZ / Str.stepZ;
        dimTP = floor(dimT / dimZ);
        
        fd = fopen([namePath, '\', nameFile], 'r'); % file to read
        if flgSave
            fdr = writeICE(nan, nan, [namePath, '\', nameFileNew], nan, []); % new file to write
            fdm = writeICE(nan, nan, [namePath, '\', nameFileMax], nan, []); % another file for MIP
        end
        d = dir([namePath, '\', nameFile]);
        if d.bytes > threshSizeFile
            numChunks = ceil(d.bytes / threshSizeFile);
            if numChunks > dimTP
                numChunks = dimTP;
            end
            dimCh = floor(dimTP / numChunks);
            remCh = rem(dimTP, numChunks);
        else
            numChunks = 1;
            dimCh = dimTP;
            remCh = 0;
        end
        
        if flgRegistration && strcmp(channelNum, '1')
            shifts = zeros(4, dimTP);
        end
        
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function updateChunkIndeces
        if numChunks == 1 % No chunking
            frStart = 1;
            frEnd = dimT;
            tpStart = 1;
            dimChTp = dimTP;
        elseif chn > numChunks % The remaining chunk
            frStart =  (chn - 1) * dimCh * dimZ + 1;
            frEnd = dimT;
            tpStart =  (chn - 1) * dimCh + 1;
            dimChTp = (frEnd - frStart + 1) / dimZ;
        else % Middle of the stack
            frStart =  (chn - 1) * dimCh * dimZ + 1;
            frEnd = chn * dimCh * dimZ;
            tpStart =  (chn - 1) * dimCh + 1;
            dimChTp = (frEnd - frStart + 1) / dimZ;
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function stackD = deconvolveImages(stack)
        
        [~, s.hostname] = system('hostname');
        s.hostname = strtrim(s.hostname);
        switch s.hostname
            case 'micromanager'
                waitInitial = 200;
            otherwise
                waitInitial = 0;
        end
        
        if rem(dimZ, 2) % If Z-dimension of psf is odd
            dimZPsf = dimZ + 3;
        else
            dimZPsf = dimZ + 2;
        end
        psf = generatePSF(dimX, dimY, dimZPsf, 0, 30); % Generate Gaussian PSF
        if flgGpu
            ijPsf = MIJ.createImage('psf', psf, true);
            ijPsf.getWindow.setVisible(false);
            MIJ.run('Swap Quadrants 3D');       % Swap quadrants for GPU-based deconvolution
            psf = stackIJ2stackMat(ijPsf, dimX, dimY, dimZPsf);
            ijPsf.changes = false();
            ijPsf.close();
        end
        
        if flgGpu % Deconvolution on GPU
            prt('Deconvolving on GPU...');
            if flgGui
                updateElapsedTime(handles, s.tWhole);
                set(handles.textProcess,'String', 'Deconvolution');
                set(handles.textMessage,'String', 'Deconvolving on GPU...');
                drawnow;
            end
            
            for waitAfterDecon = waitInitial:500:5000
                sleep(2000);
                reset(parallel.gpu.GPUDevice.current()); % GPU needs to be reseted
                sleep(2000);
                [stackD, isFinished, s.numGpuErr] = deconvCuda(stack, psf, 100, s.numGpuErr,...
                    dimX, dimY, dimZ, dimChTp, tpStart, waitAfterDecon, flgGui, handles, s.tWhole);
                if isFinished
                    break;
                end
            end
            if ~isFinished
                error('Deconvolution failed.');
            end
            
            java.lang.Thread.sleep(2000); % Give GPU some time to settle down, otherwise it'll crash
            reset(parallel.gpu.GPUDevice.current()); % GPU needs to be reseted before using gpuArray function
            
        else % Deconvolution on CPU
            stackD = nan(dimX, dimY, dimZ, dimChTp);
            for tpCh = 1:dimChTp
                if flgGui
                    updateElapsedTime(handles, s.tWhole);
                    drawnow;
                end
                % Load a stack
                stack = openICE( (tpCh - 1) * dimZ + 1, dimZ, [namePath, '\', nameFile]);
                % Deconvolution
                prt('Deconvolving on CPU', nameFile, ': T = ', tpCh, '/', dimChTp);
                
                % Deconvolution in ImageJ
                stackD(:, :, :, tpCh) = deconvij(stack, psf, 7, 8, 1);
            end
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function stackM = createMip(stack)
%         stack = reshape(stack, dimX, dimY, dimZ, dimChTp);
        stackM = squeeze( max(stack, [], 3) );
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function [stackR, stackMR] = registerImages(stack, stackM)
        
        stackR = nan(dimY, dimX, dimZ, dimChTp);
        stackMR = nan(dimY, dimX, dimChTp);
        
        if chn == 1
            stackMPrev = stackM(:, :, 1);
        end
        prt('Registering...');
        if flgGui
            updateElapsedTime(handles, s.tWhole);
            set(handles.textProcess,'String', 'Registration');
            if flgGpu
                set(handles.textMessage,'String', 'Registering on GPU...');
            else
                set(handles.textMessage,'String', 'Registering on CPU...');
            end
            drawnow;
        end
        drawnow;
        for tpCh = 1:dimChTp
            tp = tpStart + tpCh - 1;
            if strcmp(channelNum, '1') % Calculate shifts on red channel
                if flgGpu
                    shifts(:, tp) = dftregistrationGPU...
                        (fft2(gpuArray(stackMPrev)),...
                        fft2(gpuArray(stackM(:, :, tpCh))), 10);
                else
                    for ch = 1:1
                        shifts(:, tp) = dftregistration...
                            (fft2((stackMPrev)),...
                            fft2((stackM(:, :, tpCh))), 10);
                    end
                end
                if tp > 1 % Summation of shift vectors
                    shifts(:, tp) = shifts(:, tp - 1) + shifts(:, tp);
                end
                stackMPrev = stackM(:, :, tpCh); % This will be used for the next chunk
            end
            
            if flgGpu
                % Shift the images
                for ch = 1
                    for z = 1 : dimZ
                        stackR(:, :, z, tpCh) = shiftImageSubpixelGPU(gpuArray...
                            (double(stack(:, :, z, tpCh))), shifts(3, tp), shifts(4, tp));
                    end
                    stackMR(:, :, tpCh) = shiftImageSubpixelGPU(gpuArray...
                        (double(stackM(:, :, tpCh))), shifts(3, tp), shifts(4, tp));
                end
            else
                % Shift the images
                for ch = 1
                    for z = 1 : dimZ
                        stackR(:, :, z, tpCh) =...
                            shiftImageSubpixel...
                            (double(stack(:, :, z, tpCh)), shifts(3, tp), shifts(4, tp));
                    end
                    stackMR(:, :, tpCh) = shiftImageSubpixelGPU(gpuArray...
                        (double(stackM(:, :, tpCh))), shifts(3, tp), shifts(4, tp));
                end
            end
        end
        stackR = uint16(stackR);        % Moke sure the stack is uint16 otherwise it'll be very slow to fwrite
        stackMR = uint16(stackMR);
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function saveIce(stack, stackM)

        if flgGui
            updateElapsedTime(handles, s.tWhole);
            set(handles.textProcess,'String', 'Data I/O');
            set(handles.textMessage,'String', 'Saving the file...');
            drawnow;
        end
        
        % Write to a new ice file
        %         writeICE( fdr, reshape( stack, 1, dimX * dimY * (frEnd - frStart + 1) ) );
        prt('Saving:', nameFileNew);
        tI = tic;
        writeICE(fdr, stack);
        prt('Saving:', nameFileMax);
        writeICE(fdm, stackM);
        s.tSave = s.tSave + toc(tI);
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function finalizeIce
        
        if flgSave
            % Copy the header and finalize the ice file
            sH = readHeaderICE([namePath, '\', nameFile]);
            writeHeaderICE(fdr, sH); % Just copy the original header
            sH.dimZ = 1; % Reduce dimensionality of MIP
            sH.stepZ = 1;
            writeHeaderICE(fdm, sH); % Copy the modified header
        end
        
        if ~isempty(fd) && ~isempty( fopen(fd) ), fclose(fd); end
        if ~isempty(fdr) && ~isempty( fopen(fdr) ), fclose(fdr); end
        if ~isempty(fdm) && ~isempty( fopen(fdm) ), fclose(fdm); end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function trackNuclei
        if flgGui
            nameFileNew(5) = '1';
            set(handles.textFile,'String', nameFileNew);
            drawnow;
        end
        if flgTracking
            msg = displayICE([namePath, '\', nameFileNew], false, 'track', flgGui, handles, s.tWhole, s.threshSeed);
        end

        if flgGui
            updateElapsedTime(handles, s.tWhole);
            set(handles.textMessage,'String',  ['Completed in ', num2str(toc(s.tWhole)), ' seconds']);
            drawnow;
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function finalizeBatch
        
        prt('Number of GPU errors:', s.numGpuErr);
        prt('Deconvolution:', s.tDecon, 'seconds');
        prt('Registration:', s.tReg, 'seconds');
        prt('Tracking:', s.tTrack, 'seconds');
        prt('Loading:', s.tLoad, 'seconds');
        prt('Saving:', s.tSave, 'seconds');
        prt('%0.1f',...
            'Analysis complete: Total time is',...
            toc(s.tWhole), 'seconds (',...
            toc(s.tWhole)/60, 'minutes or',...
            toc(s.tWhole)/3600, 'hours ).');
        s.tWhole = toc(s.tWhole);
        if ~isempty(msg)
            s.warning = msg.warning;
        end
        if flgDeconvolution
            MIJ.exit;
        end
    end

end
