function [g, SM] = otsu(f)
% [g, SM] = otsu(f)
%
% Receives an image (f)
% Returns the segmented image of f (g) using Otsu's method and the
% separability measure (SM)

f = mat2gray(f);            % Convert to grayscale
[T, SM] = graythresh(f);    % T = thredhold, SM = separability measure
g = im2bw(f, T);            % Output the binary image thresholded with T
%g = f > T;