function [segm, num_segm, sink, dx, dy] = grad_flow_segm(f, mesg, filters)
% [segm, sink, num_segm, sink, dx, dy] = grad_flow_segm(f, mesg)
%
%------------------------------Description---------------------------------
%
% Segments the given image by determining its gradient vector field and 
% collecting together the points that lead to the same sink 
% (see gradient_flow_track2.m)
%
% -------------------------------Input-------------------------------------
%
% f         : Image file (2-D matrix)
% mesg      : Displays time messages if mesg = 1
%
% ------------------------------Output-------------------------------------
%
% segm      : Segmented image of f with each region labelled with a
%             different integer
% num_segm  : Total number of segmented regions
% sink      : num_seg x 3 matrix where the first column contains region
%             identifiers (integer), second and third columns each contain
%             row and column coordinates 
% dx, dy    : Gradient vector field used for segmentation
%
% ------------------------------Notes--------------------------------------
%
% 130607 assumes that the given image is already pre-processed
% 130626 returns gradient vector field

if nargin < 2
    mesg = 1;   % Default = messages displayed
end

%% Gradient vector field
start2 = tic;

[dx dy] = gradient(double(f));  % Gradient vector field

% Gradient vector flow tracking
f = mat2gray(f);        % For thresholding
T = graythresh(f);      % Threshold (via Otsu) to separate the background points that may have nonzero gradient

[segm, sink, num_segm] = gradient_flow_track(f,dx,dy,filters); % Main part

if mesg % Display time messages
    end2 = toc(start2);
    fprintf(['Gradient vector field tracking: ', num2str(end2), ' seconds\n'])
end