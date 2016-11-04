function [R, C] = local_max_gvf(img, filters, threshSeed)

img_proc = img - threshSeed;

% img_proc = pre_process(img_orig);     % Pre-processing


% se = strel('disk', 14);
% 
% img_proc = imtophat(f, se);


[c_segm, n_segm, c_sink, c_dx, c_dy] = grad_flow_segm(img_proc, 0, filters); % Segmentation using gradient vector field
c_sink = c_sink(:,2:3);   % Don't need region identifiers (first column of sink)

% R = c_sink(:, 1);
% C = c_sink(:, 2);

[sink, c_segm] = post_process_in(c_sink, c_segm, img_proc);  % Post-processing
R = sink(:, 1);
C = sink(:, 2);


% w2 = fspecial('disk', 5);
% img = imfilter(img, w2, 'circular');
% % Smooth the image
% w1 = fspecial('disk',14);
% img_back = imfilter(img,w1,'circular');
% img = img - img_back;
% 
% 
% 
% % Separate neurons from the background
% %img = double(img).*otsu(img);
% 
% % Get local maxima
% a = [1,1,1;1,0,1;1,1,1];
% %a = [1,1,1,1,1;1,1,1,1,1;1,1,0,1,1;1,1,1,1,1;1,1,1,1,1];
% figure;imagesc(img);
% bw = img > imdilate(img, a);
% figure;imagesc(bw);
% bw = mat2gray(img).*bw >= graythresh(mat2gray(img)) * .4;
% figure;imagesc(bw);