function [shiftX, shiftY] = findImageOffset(imgPrev, img)


% %% Crop the template image for speeding-up the NCC
% imgCrop = img(129:384, 129:384);

%% Get image shifts in x and y

matCorr = normxcorr2(img, imgPrev); % Correlation matrix

centre = ceil(size(matCorr)/2);   % Centre point of the correlation matrix

[~, I] = max(matCorr(:));  % Index of the maximum correlation

[maxY, maxX] = ind2sub(size(matCorr), I);  % Row-column coordinate of the maximum

shiftY = maxY - centre(1);
shiftX = maxX - centre(2);


end