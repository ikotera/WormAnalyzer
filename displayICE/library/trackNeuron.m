function [pos, segm_crop, int_ratio, int_g, int_r, segm_crop_pos, dx_sn, dy_sn] = trackNeuron(...
    sliceZ, dimT, dimZ, dimR, dimC, crop_size_r, crop_size_c, r_init, c_init, fr_init, fr_fin, ...
    segm_crop_barrier, segm_crop_pos_barrier) %#codegen

% function [pos, segm_crop, int_ratio, int_g, int_r, segm_crop_pos, dx_sn, dy_sn] = trackNeuron(sliceZ, dimT, dimZ, dimR,...
%     dimC, ND, crop_size_r, crop_size_c, pathICE1, pathICE2, ...
%     imgMap1, imgMap2, r_init, c_init, fr_init, fr_fin, z, modeImage, ...
%     segm_crop_barrier, segm_crop_pos_barrier)
% 140306 Added tracking with barrier



% Determine if barrier is given
if ~isempty(segm_crop_barrier) && ~isempty(segm_crop_pos_barrier)
    barrier = 1;
else
    barrier = 0;
end

% imgRAM1 = nan;
% imgRAM2 = nan;

r_width = (crop_size_r - 1) / 2;
c_width = (crop_size_c - 1) / 2;

r = r_init;
c = c_init;

int_ratio = zeros(dimT/dimZ, 1);
int_g = zeros(dimT/dimZ, 1);
int_r = zeros(dimT/dimZ, 1);
%         segm = zeros(dimR,dimC,dimT/dimZ);
dx_sn = zeros(crop_size_r, crop_size_c, dimT/dimZ);
dy_sn = zeros(crop_size_r, crop_size_c, dimT/dimZ);
pos = zeros(dimT/dimZ, 2);
%         pos(fr_init,1) = r_init;
%         pos(fr_fin,2) = c_init;
segm_crop_pos = nan(dimT/dimZ, 4);
segm_crop = false(crop_size_r, crop_size_c, dimT/dimZ);

for t = fr_init:fr_fin

    r_min = max(1, r - r_width);
    r_max = min(dimR, r + r_width);
    c_min = max(1, c - c_width);
    c_max = min(dimC, c + c_width);

    img1 = sliceZ{1}(:, :, t);
    img2 = sliceZ{2}(:, :, t);
%     readImage(t, dimT, z, dimZ, pathICE1, ND, modeImage, imgRAM1, imgMap1);
%     img2 = readImage(t, dimT, z, dimZ, pathICE2, ND, modeImage, imgRAM2, imgMap2);

    AOI1 = double(img1(r_min:r_max, c_min:c_max));
    AOI2 = double(img2(r_min:r_max, c_min:c_max));
    

    % Pad the cropped images with 0's if it's smaller than it should be (130827)
    if(size(AOI1, 1) < crop_size_r && r_min == 1)               % top
        AOI1 = padarray(AOI1, [crop_size_r - size(AOI1, 1), 0], 'pre');
        AOI2 = padarray(AOI2, [crop_size_r - size(AOI2, 1), 0], 'pre');
    elseif(size(AOI1, 1) < crop_size_r && r_max >= dimR)        % bottom
        AOI1 = padarray(AOI1, [crop_size_r - size(AOI1, 1), 0], 'post');
        AOI2 = padarray(AOI2, [crop_size_r - size(AOI2, 1), 0], 'post');
    end
    
    if(size(AOI1, 2) < crop_size_c && c_min == 1)           % left
        AOI1 = padarray(AOI1, [0, crop_size_c - size(AOI1, 2)], 'pre');
        AOI2 = padarray(AOI2, [0, crop_size_c - size(AOI2, 2)], 'pre');
    elseif(size(AOI1, 2) < crop_size_c && c_max >= dimC)        % right
        AOI1 = padarray(AOI1, [0, crop_size_c - size(AOI1, 2)], 'post');
        AOI2 = padarray(AOI2, [0, crop_size_c - size(AOI2, 2)], 'post');
    end

    % Determine barrier
    AOIBarrier = zeros(size(AOI1));
    if barrier
        r_minb = segm_crop_pos_barrier(t, 1);
        r_maxb = segm_crop_pos_barrier(t, 2);
        c_minb = segm_crop_pos_barrier(t, 3);
        c_maxb = segm_crop_pos_barrier(t, 4);
        
        r_min_overlap = max(r_min, r_minb);
        r_max_overlap = min(r_max, r_maxb);
        c_min_overlap = max(c_min, c_minb);
        c_max_overlap = min(c_max, c_maxb);
        
        AOIBarrier = zeros(size(AOI1));
        
        r1min = 1 + r_min_overlap - r_min;
        r1max = 1 + r_max_overlap - r_min;
        c1min = 1 + c_min_overlap - c_min;
        c1max = 1 + c_max_overlap - c_min; 
        
        r2min = 1 + r_min_overlap - r_minb;
        r2max = 1 + r_max_overlap - r_minb;
        c2min = 1 + c_min_overlap - c_minb;
        c2max = 1 + c_max_overlap - c_minb;

        cond1 = r1min > 0 && r1max <= size(AOIBarrier, 1);
        cond2 = c1min > 0 && c1max <= size(AOIBarrier, 2);
        cond3 = r2min > 0 && r2max <= size(AOIBarrier, 1);
        cond4 = c2min > 0 && c2max <= size(AOIBarrier, 2);
        
        if cond1 && cond2 && cond3 && cond4
            BarrierSection = segm_crop_barrier(r2min:r2max, c2min:c2max, t);
            AOIBarrier(r1min:r1max, c1min:c1max) = BarrierSection;
        end
    end    

    % Segmentation
    filterBack = fspecial('disk', 14);
    filterSmooth = fspecial('disk', 3);
    back = double(imfilter(AOI1, filterBack, 'replicate'));    % Estimated background
    AOI1Subt = AOI1 - back;                        % Background subtracted from raw
    AOI = imfilter(AOI1Subt, filterSmooth, 'replicate');    % Smoothing
    AOI = AOI.*otsu(AOI);                   % Initial segmentation
    
    % Gradient vector tracking
    [dx_sn(:, :, t), dy_sn(:, :, t)] = gradient(AOI);
    T = graythresh(AOI);
    
    if nnz(dx_sn(:,:,t)) == 0 && nnz(dy_sn(:,:,t)) == 0
        break;
    end
    
    if any(AOI(~AOIBarrier) ~= 0)
        
        segm_crop(:, :, t) = logical...
            (individual_analysis_trackGVF(AOI,dx_sn(:, :, t), dy_sn(:, :, t), T, AOIBarrier));
        
    else
        segm_crop(:, :, t) = zeros(crop_size_r, crop_size_c);
        segm_crop(ceil(crop_size_r / 2), ceil(crop_size_c / 2), t) = 1;
    end
    
    % Store postions of cropped segmentations
    segm_crop_pos(t, 1) = r_min;
    segm_crop_pos(t, 2) = r_max;
    segm_crop_pos(t, 3) = c_min;
    segm_crop_pos(t, 4) = c_max;
    
%     segm(r_min:r_max,c_min:c_max,t) = segmcrop;
%     GVF_dx{z}(r_min:r_max,c_min:c_max,t) = dx;
%     GVF_dy{z}(r_min:r_max,c_min:c_max,t) = dy;
    
    % Determine centre point
    centre = regionprops(segm_crop(:, :, t), AOI, 'WeightedCentroid');
    centre = round(centre.WeightedCentroid);
    
    if any(isnan(centre))
        centre = regionprops(segm_crop(:, :, t), 'Centroid');
        centre = round(centre.Centroid);
    end
    
    % Calculate intensity ratio
    int_r(t) = avg_int_region(AOI1, segm_crop(:, :, t));
    int_g(t) = avg_int_region(AOI2, segm_crop(:, :, t));
    
    int_ratio(t) = int_g(t) ./ int_r(t);
    
    r = r_min + centre(2) - 1;
    c = c_min + centre(1) - 1;
    
    pos(t,1) = r;
    pos(t,2) = c;
    

    
end


end