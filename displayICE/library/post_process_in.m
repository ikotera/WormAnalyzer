function [CoM segm_p] = post_process_in(CoM, segm, proc)
% [CoM_p segm_p] = post_process(CoM, segm)
%
%------------------------------Description---------------------------------
%
% Post-processes the segmented image
% Includes local thresholding (using otsu) and small region removing
%
% -------------------------------Input-------------------------------------
%
% CoM       : Centre points matrix
% segm      : Segmented image
% proc      : Processed image
%
% ------------------------------Output-------------------------------------
%
% CoM_p     : Centre points for high-confidence neurons
% segm_p    : Segmented image for high-confidence neurons

new_segm = zeros(size(segm));   % New segmented ith image
min_area = 20;                  % Minimum size for a neuron

j = 1;
while j <= size(CoM, 1);        % Loop through each point
    r = CoM(j,1);                                   % Row and column coordinates of the point
    c = CoM(j,2);
    
    identifier = double(segm(r, c));                % Identifier # of this region
    region = double(proc).*(segm == identifier);    % Extract the region
    region = uint16(region);
    
    % Local thresholding
    region_otsu = otsu(region);                     % Locally thredhold that region via otsu
    
    % Region pruning
    area = regionprops(region_otsu, 'Area');        % Get the area of the region
    area = area.Area;                               % Extract the area number
    
    if area < min_area
        CoM(j,:) = [];                          % Remove the point
        j = j - 1;                              % Reset the counter
    else
        new_segm = new_segm + identifier*region_otsu;   % Record it to the new segmented image
    end
    j = j + 1;
end

segm_p = uint16(new_segm);