function avg_int = avg_int_region(img, region)
% avg_int = avg_int_region(region)
%
% Receives the masked region (region) and the image (img) and returns the
% average intensity of the image in that region

isolated_region = img(region);  % Isolate the region corresponding to the mask
npix = nnz(region);             % Size (number of points) of the particle

total_int = sum(isolated_region(:));    % Total intensity (simple sum)

avg_int = total_int / npix;             % Average intensity