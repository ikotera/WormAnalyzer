function [ img ] = filterImage( img, filters )


img = img - filters.threshBack * filters.multiplier;            % Subtract background

back = imfilter(img, filters.lowpassForBackground, 'replicate');
img = img - back;                                               % Subtract low frequency components

img = imfilter(img, filters.lowpassForSmoothing, 'replicate');  % Image smoothing

end

