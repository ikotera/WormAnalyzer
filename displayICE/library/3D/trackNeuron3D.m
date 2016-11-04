function [pos, segm_crop, int_ratio, segm_crop_pos, dx_sn, dy_sn, dz_sn] = trackNeuron3D(dimT, ...
    dimZ, dimR, dimC, ND, crop_size_r, crop_size_c, crop_size_z, pathICE1, pathICE2, ...
    imgMap1, imgMap2, r_init, c_init, z_init, fr_init, fr_fin, modeImage, ...
    segm_crop_barrier, segm_crop_pos_barrier)
% 140306 Added tracking with barrier

% Determine if barrier is given
if ~isempty(segm_crop_barrier) && ~isempty(segm_crop_pos_barrier)
    barrier = 1;
else
    barrier = 0;
end

imgRAM1 = nan;
imgRAM2 = nan;

r_width = (crop_size_r - 1) / 2;
c_width = (crop_size_c - 1) / 2;
z_width = (crop_size_z - 1) / 2;

r = r_init;
c = c_init;
z = z_init;

int_ratio = zeros(1,dimT/dimZ);
%         segm = zeros(dimR,dimC,dimT/dimZ);
dx_sn = zeros(crop_size_r, crop_size_c, crop_size_z, dimT/dimZ);
dy_sn = zeros(crop_size_r, crop_size_c, crop_size_z, dimT/dimZ);
dz_sn = zeros(crop_size_r, crop_size_c, crop_size_z, dimT/dimZ);
pos = zeros(dimT/dimZ, 3);
%         pos(fr_init,1) = r_init;
%         pos(fr_fin,2) = c_init;
segm_crop_pos = nan(dimT/dimZ, 6);
segm_crop = false(crop_size_r, crop_size_c, crop_size_z, dimT/dimZ);

for t = fr_init:fr_fin
    r_min = max(1, r - r_width);
    r_max = min(dimR, r + r_width);
    c_min = max(1, c - c_width);
    c_max = min(dimC, c + c_width);
    z_min = max(1, z - z_width);
    z_max = min(dimZ, z + z_width);
    
    img1 = zeros(dimR, dimC, crop_size_z);
    img2 = zeros(dimR, dimC, crop_size_z);
    
    for i = z_min:z_max
        index = i - z_min + 1;
        img1(:,:,index) = readImage(t, dimT, z, dimZ, pathICE1, ND, modeImage, imgRAM1, imgMap1);
        img2(:,:,index) = readImage(t, dimT, z, dimZ, pathICE2, ND, modeImage, imgRAM2, imgMap2);
    end
    
    AOI1 = uint16(img1(r_min:r_max, c_min:c_max, :));
    AOI2 = uint16(img2(r_min:r_max, c_min:c_max, :));
    
    % Determine barrier
    AOIBarrier = zeros(size(AOI1));
    if barrier
        r_minb = segm_crop_pos_barrier(t, 1);
        r_maxb = segm_crop_pos_barrier(t, 2);
        c_minb = segm_crop_pos_barrier(t, 3);
        c_maxb = segm_crop_pos_barrier(t, 4);
        z_minb = segm_crop_pos_barrier(t, 5);
        z_maxb = segm_crop_pos_barrier(t, 6);
        r_min_overlap = max(r_min, r_minb);
        r_max_overlap = min(r_max, r_maxb);
        c_min_overlap = max(c_min, c_minb);
        c_max_overlap = min(c_max, c_maxb);
        z_min_overlap = max(z_min, z_minb);
        z_max_overlap = min(z_max, z_maxb);
        
        AOIBarrier = zeros(size(AOI1));
        
        r1min = 1 + r_min_overlap - r_min;
        r1max = 1 + r_max_overlap - r_min;
        c1min = 1 + c_min_overlap - c_min;
        c1max = 1 + c_max_overlap - c_min; 
        z1min = 1 + z_min_overlap - z_min;
        z1max = 1 + z_max_overlap - z_min; 
        
        r2min = 1 + r_min_overlap - r_minb;
        r2max = 1 + r_max_overlap - r_minb;
        c2min = 1 + c_min_overlap - c_minb;
        c2max = 1 + c_max_overlap - c_minb;
        z2min = 1 + z_min_overlap - z_minb;
        z2max = 1 + z_max_overlap - z_minb;

        cond1 = r1min > 0 && r1max <= size(AOIBarrier, 1);
        cond2 = c1min > 0 && c1max <= size(AOIBarrier, 2);
        cond3 = r2min > 0 && r2max <= size(AOIBarrier, 1);
        cond4 = c2min > 0 && c2max <= size(AOIBarrier, 2);
        cond5 = z1min > 0 && z1max <= size(AOIBarrier, 3);
        cond6 = z2min > 0 && z2max <= size(AOIBarrier, 3);
        
        if cond1 && cond2 && cond3 && cond4 && cond5 && cond6
            BarrierSection = segm_crop_barrier(r2min:r2max, c2min:c2max, z2min:z2max, t);
            AOIBarrier(r1min:r1max, c1min:c1max, z1min:z2max) = BarrierSection;
        end
    end
    
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
    
    if(size(AOI1, 3) < crop_size_z && z_min == 1)               % z-bottom
        AOI1 = padarray(AOI1, [0, 0, crop_size_z - size(AOI1, 3)], 'pre');
        AOI2 = padarray(AOI2, [0, 0, crop_size_z - size(AOI2, 3)], 'pre');
    elseif(size(AOI1, 3) < crop_size_z && z_max >= dimZ)        % z-top
        AOI1 = padarray(AOI1, [0, 0, crop_size_z - size(AOI1, 3)], 'post');
        AOI2 = padarray(AOI2, [0, 0, crop_size_z - size(AOI2, 3)], 'post');
    end

    % Segmentation
    filterBack = fspecial('disk', 14);
    filterSmooth = fspecial('disk', 3);
    
    AOI = uint16(zeros(crop_size_r, crop_size_c, crop_size_z));
    
    for i = z_min:z_max
        index = i - z_min + 1;
        back = imfilter(AOI1(:,:,index), filterBack, 'replicate');  % Estimated background
        AOI1Subt = AOI1(:,:,index) - back;                          % Background subtracted from raw
        AOI(:,:,index) = imfilter(AOI1Subt, filterSmooth, 'replicate');    % Smoothing
        AOI(:,:,index) = AOI(:,:,index).*uint16(otsu(AOI(:,:,index)));     % Initial segmentation
    end
    
    AOI = double(AOI);
    
    % Gradient vector tracking
    [dx_sn(:,:,:,t), dy_sn(:,:,:,t), dz_sn(:,:,:,t)] = gradient(AOI);
    T = zeros(1, crop_size_z);
    for i = z_min:z_max
        index = i - z_min + 1;
        T(index) = graythresh(AOI(:,:,index));
    end
    
    if nnz(dx_sn(:,:,:,t)) == 0 && nnz(dy_sn(:,:,:,t)) == 0 && nnz(dz_sn(:,:,:,t)) == 0
        break;
    end

    segm_crop(:, :, :, t) = logical(individual_analysis_trackGVF3D(AOI,dx_sn(:,:,:,t), dy_sn(:,:,:,t), dz_sn(:,:,:,t), T, AOIBarrier));
    
    % Store postions of cropped segmentations
    segm_crop_pos(t, 1) = r_min;
    segm_crop_pos(t, 2) = r_max;
    segm_crop_pos(t, 3) = c_min;
    segm_crop_pos(t, 4) = c_max;
    segm_crop_pos(t, 5) = z_min;
    segm_crop_pos(t, 6) = z_max;
    
    %             segm(r_min:r_max,c_min:c_max,t) = segmcrop;
%     GVF_dx{z}(r_min:r_max,c_min:c_max,t) = dx;
%     GVF_dy{z}(r_min:r_max,c_min:c_max,t) = dy;
    
    % Determine centre point
    centre = regionprops(segm_crop(:, :, :, t), AOI, 'WeightedCentroid');
    centre = round(centre.WeightedCentroid);
    
    % Calculate intensity ratio
    aI1 = avg_int_region(AOI1, segm_crop(:, :, :, t));
    aI2 = avg_int_region(AOI2, segm_crop(:, :, :, t));
    
    int_ratio(t) = aI2./aI1;
    
    r = r_min + centre(2) - 1;
    c = c_min + centre(1) - 1;
    z = z_min + centre(3) - 1;
    
    pos(t,1) = r;
    pos(t,2) = c;
    pos(t,3) = z;
    
    
end


end