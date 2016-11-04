function [CoM_p segm_p] = post_process(CoM, segm, proc)
% [CoM_p segm_p] = post_process(CoM, segm)
%
%------------------------------Description---------------------------------
%
% Post-processes the results of the segmentation process
% Includes local thresholding (using otsu) and speck removing
%
% -------------------------------Input-------------------------------------
%
% CoM       : Centre points data
% segm      : Segmented images
% proc      : Processed images (1xn cell)
%
% ------------------------------Output-------------------------------------
%
% CoM_p     : Centre points for high-confidence neurons (1xn cell)
% segm_p    : Segmented images for high-confidence neurons (1xn cell)


n = numel(segm);   % Number of images

% Local thresholding
segm_p = cell(size(segm));  % Preallocation for new segmented map

for i = 1:n     % Loop through each image
    m = size(CoM{i},1);                 % Number of points
    new_segm = zeros(size(segm{i}));    % New segmented ith image
    
    for j = 1:m     % Loop through each point
        identifier = segm{i}(CoM{i}(j,1),CoM{i}(j,2));  % Identifier # of this region
        region = mat2gray(proc{i}).*(segm{i}==identifier);   % Extract the region
        region_otsu = otsu(region);     % Locally threshold that region via otsu
        new_segm = new_segm + identifier*region_otsu; % Record it to the new segmented image
    end
    
    segm_p{i} = new_segm;
end

% Speck removing
CoM_p = cell(size(CoM));    % Preallocation for neuron points
min_area = 25;  % Minimum size for a neuron

for i = 1:n     % Loop through each image
    centre_points = CoM{i};
    
    j = 1;
    while j <= size(centre_points, 1);
        r = centre_points(j,1); % Row and column coordinates of the point
        c = centre_points(j,2);
        
        identifier = segm_p{i}(r,c);
        region = segm_p{i} == identifier;     % Extract the region
        area = regionprops(region, 'Area'); % Get the area of the region
        area = area.Area;                   % Extract the area number
        if area < min_area
            centre_points(j,:) = [];                % Remove the point
            segm_p{i}(segm_p{i} == identifier) = 0; % Remove the region
            j = j - 1;  % Reset the counter
        end
        j = j + 1;
    end
    CoM_p{i} = centre_points;
end