function hl = strechHist(img, satLow, satHigh, depth)


numZeros = size(img(img == 0), 1);

img(img == 0) = [];
minImg = min(img(:));
img = [repmat(minImg, 1, numZeros), img];
bins = linspace(0, depth-1, depth);
H = hist(img(:), bins);
H(H == 0) = eps(sum(H));
cdf = [0, cumsum(H) / sum(H)];
hl(2) = interp1(cdf, [0, bins], satLow);
hl(1) = interp1(cdf, [0, bins], satHigh);

end