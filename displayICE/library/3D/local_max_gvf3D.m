function [R, C, Z] = local_max_gvf3D(img)

img_orig = img;
img_proc = zeros(size(img_orig));

dimZ = size(img_orig,3);

for i = 1:dimZ
    img_proc(:,:,i) = pre_process(img_orig(:,:,i));     % Pre-processing
end

[c_segm, n_segm, c_sink, c_dx, c_dy, c_dz] = grad_flow_segm3D(img_proc); % Segmentation using gradient vector field
c_sink = c_sink(:,2:4);   % Don't need region identifiers (first column of sink)

%[sink, c_segm] = post_process_in(c_sink, c_segm, img_proc);  % Post-processing
R = c_sink(:, 1);
C = c_sink(:, 2);
Z = c_sink(:, 3);