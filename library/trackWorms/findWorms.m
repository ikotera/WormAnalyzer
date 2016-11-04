function [listCentroid, listArea, tophat] = findWorms(img, sizeImage, threshBin, threshArea)

% Perform tophat filter on GPU
se = strel('disk', 5);

if isGpuAvailable
    G = gpuArray(img);
    gtophat = imtophat(G, se);
    tophat = gather(gtophat);
else
    tophat = imtophat(img, se);
end

% Convert the image to binary
bw = im2bw(tophat, threshBin);
lables = bwlabel(bw);

% Compute indeces of worm pixels
numWorms = round(double(max(lables(:))));
listIndex = regionpropsmex(lables, numWorms); % Requires regionpropsmex.mexw64 in MATLAB's path

% Discard small objects
listArea = cellfun('size', listIndex, 1);
idx = listArea > threshArea;
listIndex = listIndex(idx, 1);
listArea = listArea(idx, 1);
numWorms = size(listIndex, 1);

% Compute centroids of the worms
In = cell(1, 2);
listPixel = cell(numWorms, 1);
listCentroid = nan(numWorms, 2);
for k = 1:numWorms
    if ~isempty(listIndex(k))
        [In{:}] = ind2sub(sizeImage, listIndex{k});
        listPixel{k, 1} = [In{:}];
        listPixel{k, 1} = listPixel{k, 1}(:, [2 1 3:end]); % Permutate columns
        listCentroid(k, :) = mean(listPixel{k}, 1);
    else
        listPixel = zeros(0, 2);
    end
end


end
