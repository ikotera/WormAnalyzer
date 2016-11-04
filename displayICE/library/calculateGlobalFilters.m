function [ filters ] = calculateGlobalFilters( stackFirst )

filters.multiplier = 1.3;

stackFirst( stackFirst == max( stackFirst(:) ) ) = [];  % Remove saturated pixels

[counts, x] = imhist(stackFirst(:), 2^16);              % Histogram of the first image stack

peak = max(counts);                                     % The peak (background)
hm = peak / 2;                                          % Half-max of the peak
fwhm = numel( counts(counts > hm) );                    % Full width half maximum
idx = find( counts == peak ) + fwhm * 2;                % Indeces of background peak range
filters.threshBack = x(idx);                            % Background threshold for the stack (global)

filters.lowpassForBackground = fspecial('disk',12);     % Filter for background estimation
filters.lowpassForSmoothing = fspecial('gaussian' ,4);  % Filter for smoothing

end

