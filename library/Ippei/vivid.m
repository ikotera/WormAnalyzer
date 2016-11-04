function lut = vivid(maxMin)

% 1       max_____
%           /
%          /
%         /
%   _____/
% 0      min

maxMin = round(maxMin);

if any(maxMin(:, 2) < 1, 1)
    maxMin(maxMin < 1) = 1; % MATLAB index has to start from 1
end

numCh = size(maxMin, 1);
maxDepth = max(maxMin(:, 1));
lut = ones(maxDepth, numCh);

maxInt = maxMin(:, 1) - 1;
minInt = maxMin(:, 2) - 1;
depth = maxInt - minInt;

for nc = 1:numCh
    lut(1:maxInt(nc)+1, nc) = ([zeros(1, minInt(nc)), 0:depth(nc)])' / max(depth(nc), 1);
end

end