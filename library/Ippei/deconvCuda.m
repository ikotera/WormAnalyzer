function [imageStackDeconv, isFinished, numGpuErr] = deconvCuda(imageStack, psf, maxIterations, numGpuErr,...
    dimX, dimY, dimZ, dimTP, tp, waitAfterDecon, flgGUI, handles, tWhole)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                         deconvCuda.m                                             %
%                                Jan. 014, 2014 by Ippei Kotera                                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% imageStackDeconv = deconvCuda(imageStack, psf, maxIterations)
%
% This is a wrapper for Cuda Deconvolution, a plugin for ImageJ provided by Dr. Butte (Opt Express.
% 2013 Feb 25;21(4):4766-73). This function puts together all the input arguments for the plugin by
% directly calling java objects, then executes the runDecon method through ImageJ instance. It
% requires running instance of MIJ, which can be created by executing Miji if Miji package is
% installed. Make sure that the CUDA Deconvolution plugin is located in the root plugin folder
% '\Fiji.app\plugins\' so that Miji can add them to dynamic java class path of MATLAB. The input
% image stack and PSF must be 3D matrices of the same dimensions. Also make sure to allocate
% enough java heap memory from MATLAB's preferences -> General -> Java Heap Memory. The CUDA kernel
% might crash if you try to call MATLAB's gpuArray right after this function. If that happens,
% giving enough time interval (>500ms) between the calls should help. Finally copy the following dll files to
% [matlabroot, '\bin\win64']; bridj.dll, CudaDecon.dll, cudart64_50_35.dll, and cufft64_50_35.dll.
%
% ------ Example ------
%
% djp = javaclasspath('-dynamic');
% if ~isempty(djp)
%     javarmpath(djp{:}); % Clear all dynamic java paths
% end
% 
% Miji; % Start Miji
% 
% pathPSF = 'C:\Decon\PSF.tif';
% for idx = 1:10
%     psf(:, :, idx) = imread(pathPSF, 'Index', idx); % PSF
% end
% 
% pathStack = 'C:\Decon\stack.tiff';
% for idx = 1:10
%     imageStack(:, :, idx) = imread(pathStack, 'Index', idx); % Image stack
% end
% 
% imageStackDeconvolved = deconvCuda(imageStack, psf, 50); % Deconvolution

% dbstop in deconvCuda at 126 if (xc > 0.81) % this crashes MATLAB

factorScaleDepth = 4; % Scaling factor of pixel intensities after deconvolution

dp = [];
df = [];
ptPsf = [];
ptStack = [];
ptParm = [];
lenStack = dimX * dimY * dimZ;
blank = zeros(1, dimX * dimY);
lenBlank = dimX * dimY;
arDeconvAll = nan(dimX*dimY*dimZ*dimTP, 1);
arPsf = single(psf(:));

prepareDecon;

for ii = 1:dimTP

    runDecon(waitAfterDecon);
    
    if length(err) > 1
        while true
            waitAfterDecon = waitAfterDecon + 10;
            numGpuErr = numGpuErr + 1;
            prt(err');
            resetGPU;
            prepareDecon;
            runDecon(waitAfterDecon);
            if length(err) <= 1
                break;
            end
        end
    end
    
    prt('TP =', tp + ii - 1, '| T =', td, '| W =', waitAfterDecon);
    if flgGUI
        updateElapsedTime(handles, tWhole);
        set(handles.textIteration,...
            'String', ['TP = ', num2str(tp + ii - 1), ' | T = ', num2str(td),...
            ' | W = ', num2str(waitAfterDecon)]);
        drawnow;
    end

end

imageStackDeconv = reshape(uint16(arDeconvAll ./ factorScaleDepth), dimX, dimY, dimZ, dimTP);
prt('Max pixel intensity of the deconvolved stack:', max( imageStackDeconv(:) ) );
if max( imageStackDeconv(:) ) == 2^16-1
    prt('Pixels are saturated');
end

resetGPU;

isFinished = true;

if flgGUI
    updateElapsedTime(handles, tWhole);
end

    function prepareDecon
        % Instantiate Deconvolution classes
        dp = DeconvolutionParameters;
        df = DeconvolutionFactory;
        
%         % PSF
%         ptPsf = org.bridj.Pointer.pointerToFloats(arPsf); % A pointer to the PSF, make sure to keep the variable alive
%         
%         % Deconvolution parameters
%         dp.nx((dimX));
%         dp.ny((dimY));
%         dp.nz((dimZ + 2));
%         dp.iterations((maxIterations));
%         dp.ptrPsf(ptPsf);
    end

    function runDecon(wait)
        tDecon = tic;
%         dp = DeconvolutionParameters;
%         df = DeconvolutionFactory;
        
        % PSF
        ptPsf = org.bridj.Pointer.pointerToFloats(arPsf); % A pointer to the PSF, make sure to keep the variable alive
        
        % Deconvolution parameters
        dp.nx((dimX));
        dp.ny((dimY));
        dp.nz((dimZ + 2));
        dp.iterations((maxIterations));
        dp.ptrPsf(ptPsf);
        
        ptStack = org.bridj.Pointer.pointerToFloats...
            ( [blank, imageStack( (ii-1)*lenStack+1 : ii*lenStack ), blank] );
        dp.ptrImage(ptStack);
        ptParm = org.bridj.Pointer.pointerTo(dp); % A pointer to the parameter object
        
        df.preDecon(dimX, dimY, dimZ + 2);
        bool = df.runDecon(ptParm); % Main deconvolution method
        if bool, prt('CPU memory was used.'); end
        % This wait is critical for some hardware combinations. Increase this value if retrieved image
        % is not deconvolved.
        java.lang.Thread.sleep(wait);
        
        arDeconv = ptStack.getFloats; % Retrieve deconvolved image array
        df.postDecon();
        arDeconvAll( (ii-1)*lenStack+1 : ii*lenStack ) = arDeconv(1 + lenBlank:lenStack+lenBlank, 1);
        td = toc(tDecon);
        err = df.errors.getCString.toCharArray; % It's usually pointer error which has something to do with garbage collection
    end

    function resetGPU
        % Garbage collection and cleaning
        java.lang.System.gc(); % This prevents problems where some retrieved images are not deconvolved
        df.resetDevice(); % This helps if the GPU kernel crashes during GPU memory fluctuation
        java.lang.Thread.sleep(2000); % Give GPU some time to settle down, otherwise it'll crash
        reset(parallel.gpu.GPUDevice.current()); % GPU needs to be reseted
        java.lang.Thread.sleep(2000);
    end

end



