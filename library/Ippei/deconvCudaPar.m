function imageStackDeconv = deconvCudaPar(imageStack, psf, maxIterations, dimX, dimY, dimZ, dimTP)
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
% installed. Also make sure the CUDA Deconvolution plugin is located in the root plugin folder
% '\Fiji.app\plugins\' so that Miji can add them to dynamic java class path of MATLAB. The input
% image stack and PSF must be 3D matrices of the same dimensions. Finally make sure to allocate
% enough java heap memory from MATLAB's preferences -> General -> Java Heap Memory. The CUDA kernel
% might crash if you try to call MATLAB's gpuArray right after this function. If that happens,
% giving enough time interval (>500ms) between the calls should help.
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


% Instantiate Deconvolution classes
dp = DeconvolutionParameters;
df = DeconvolutionFactory;

% Image stack
% [dimX, dimY, dimZ] = size(imageStack);
% arStack = single(imageStack(:));
% ptStack = org.bridj.Pointer.pointerToFloats(arStack); % A pointer to the image stack

% PSF
arPsf = single(psf(:));
ptPsf = org.bridj.Pointer.pointerToFloats(arPsf); % A pointer to the PSF

% Deconvolution parameters
dp.nx((dimX));
dp.ny((dimY));
dp.nz((dimZ));
dp.iterations((maxIterations));

dp.ptrPsf(ptPsf);


% imageStackDeconv = zeros(dimX, dimY, dimZ*dimTP, 'uint16');

lenStack = dimX * dimY * dimZ;

for ii = 1:dimTP
    ptStack = org.bridj.Pointer.pointerToFloats(imageStack( (ii-1)*lenStack+1 : ii*lenStack) );
    dp.ptrImage(ptStack);
    ptParm = org.bridj.Pointer.pointerTo(dp); % A pointer to the parameter object
    
    % Excuting deconvolution
    df.preDecon(dimX, dimY, dimZ);
    df.runDecon(ptParm); % Main deconvolution method
    arDeconv = ptStack.getFloats; % Retrieve deconvolved image array
    df.postDecon();
    arDeconvAll( (ii-1)*lenStack+1 : ii*lenStack ) = arDeconv;
end

imageStackDeconv = reshape(uint16(arDeconvAll), dimX, dimY, dimZ, dimTP);

% Garbage collection and cleaning
java.lang.System.gc(); % This prevents problems where some retrieved images are not deconvolved
df.resetDevice(); % This helps if the GPU kernel crashes during GPU memory fluctuation



end


