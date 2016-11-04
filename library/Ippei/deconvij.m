function imageStackDeconv = deconvij(imageStack, psf, maxIterations, numThreads, showIterations)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                             deconvij.m                                  %
%                      Oct. 01, 2013 by Ippei Kotera                      %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This is a wrapper for Prallel Iterative Deconvolution 3D, a plugin for
% ImageJ. This function puts together all the input arguments for the
% plugin using java objects, then calls the deconvolution class through
% ImageJ instance. It requires running instance of MIJ, which can be
% created by typing "Miji" if Miji package is installed. Also make sure all
% the .jar files are located in the root plugin folder '\Fiji.app\plugins\'
% so that Miji can add them to dynamic java class path of MATLAB. The input
% image stack and PSF must be 3D matrices. Finally make sure to allocate
% enough java heap memory from MATLAB's preferences -> General -> Java Heap
% Memory.

% import edu.emory.mathcs.restoretools.Enums;
% import edu.emory.mathcs.restoretools.iterative.IterativeEnums;
% import edu.emory.mathcs.restoretools.iterative.wpl.WPLDoubleIterativeDeconvolver3D;
% import edu.emory.mathcs.restoretools.iterative.wpl.WPLFloatIterativeDeconvolver3D;
% import edu.emory.mathcs.restoretools.iterative.wpl.WPLOptions;
% import edu.emory.mathcs.utils.ConcurrencyUtils;

[dimX, dimY, dimZ] = size(imageStack);

% Create ImagePlus object for original image stack
imB = MIJ.createImage('Blurred', imageStack, false);

% Create ImagePlus object for PSF
imPSF = MIJ.createImage('PSF', psf, false);

% Max interation
maxIterations = int8(maxIterations);

% Create IterativeEnums object and get inner class for boundary-type argument
IteEnu = edu.emory.mathcs.restoretools.iterative.IterativeEnums;
IteEnuCla = IteEnu.getClass.getClasses;
BouCon = IteEnuCla(4).getEnumConstants;
boundary = BouCon(1); % 'REFLEXIVE'

% Get inner object for resizing-type argument
ResCon = IteEnuCla(5).getEnumConstants;
resizing = ResCon(1); % 'AUTO'

% Get inner object for output-type argument
Enu = edu.emory.mathcs.restoretools.Enums;
EnuCla = Enu.getClass.getClasses;
OutCon = EnuCla(2).getEnumConstants;
output = OutCon(4); % 'FLOAT' (32-bit)

% Get inner object for precision argument
PreCon = EnuCla(1).getEnumConstants;
precision = PreCon(2); % 'SINGLE'

% Wether to use threshold or not
useThreshold = false;

% If so, the thereshold value
threshold = -1;

% Number of threads for parallel calculation
numThreads = int8(numThreads);

% Show iterations during the process
% showIterations = true;

% Gamma value
gamma = 0;

% Low-pass filter for XY
filterXY = 1;

% Low-pass filter for Z
filterZ = 1;

% Normalize PSF
normalize = false;

% Use log convergence
logMean = false;

% Anit-ring treatment
antiRing = true;

% Whether PSF is in dB
db = false;

% Detect divergence
detectDivergence = true;

% Terminate iteration if mean delta < this percentage
changeThreshPercent = 0.01;

% Set number of threads
edu.emory.mathcs.utils.ConcurrencyUtils.setNumberOfThreads(numThreads);

% Create WPL options object
WPLOpt = edu.emory.mathcs.restoretools.iterative.wpl.WPLOptions(...
    gamma, filterXY, filterZ, normalize, logMean, antiRing, changeThreshPercent,...
    db, detectDivergence, useThreshold, threshold);

% Create appropriate deconvolution3D object and deconvolve it
if strcmp(precision, 'DOUBLE')
    WPLDouble = edu.emory.mathcs.restoretools.iterative.wpl.WPLDoubleIterativeDeconvolver3D(...
        imB, imPSF, boundary, resizing, output, maxIterations, showIterations, WPLOpt);
    imX = WPLDouble.deconvolve();
elseif strcmp(precision, 'SINGLE')
    WPLFloat = edu.emory.mathcs.restoretools.iterative.wpl.WPLFloatIterativeDeconvolver3D(...
        imB, imPSF, boundary, resizing, output, maxIterations, showIterations, WPLOpt);
    imX = WPLFloat.deconvolve();
end

% Bring back the deconvolved image stack to MATLAB from ImageJ
ist = imX.getStack();
imageStackDeconv = nan(dimX, dimY, dimZ); 
for z = 1:dimZ
    sp = ist.getProcessor(z);
    fp = sp.getPixels();
    imageStackDeconv(:, :, z) = flipud(rot90(reshape(fp, dimX, dimY), 1));
end

% Close iteration window if it's there
if showIterations
    imX.close();
end


end


