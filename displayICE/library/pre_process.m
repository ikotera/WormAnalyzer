function [f3, T] = pre_process(f)
% f3 = pre_process(f)
%
%------------------------------Description---------------------------------
%
% Pre-processes the given image and returns the result
%
% -------------------------------Input-------------------------------------
%
% f         : Image file (2-D matrix)
%
% ------------------------------Output-------------------------------------
% f3        : Pre-processed image

if size(f,3) == 3                       % Convert RGB image to grayscale
    f = rgb2gray(f);
end

w1 = fspecial('disk',14);               % Filter for background estimation
w2 = fspecial('disk',3);                % Filter for smoothing

f_back = imfilter(f,w1,'replicate');    % Estimated background
f2 = f - f_back;                        % Background subtracted from raw
f3 = imfilter(f2,w2,'replicate');       % Smoothed out image

% f_otsu = otsu(f3);                      % Otsu's method
f4 = mat2gray(f3);
T = graythresh(f4);
% if T < threshMin
%     T = threshMin;
% end
f_otsu = im2bw(f4, T/2);

% Removed 130627
%w3 = strel('disk',3);                   % Structuring element for closing
%f_otsu = imopen(f_otsu, w3);            % Morphological opening to get rid of small specks

f3 = double(f3).*f_otsu;                        % Otsu's method to get rid of leftover noise
f3 = uint16(f3);