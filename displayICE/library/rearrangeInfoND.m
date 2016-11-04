function ND = rearrangeInfoND(infoND, sortRow1, sortRow2, flgMX)

if ~exist('sortRow1', 'var')
    sortRow1 = 2;
end
if ~exist('sortRow2', 'var')
    sortRow2 = 5;
end

infoND(infoND(:, 1) == 0, :) = []; % Get rid of rows with zero seconds

% Determine slot numbers and num of cubes
planeZ = unique(infoND(:, sortRow1)); % get all z planes
slotCube = unique(infoND(:, sortRow2)); % get all the cube numbers

numZ = numel(planeZ);
numCubes = numel(slotCube);

for r1 = 1:numZ
    for r2 = 1:numCubes
        ND{r1, r2} = infoND(...
            (infoND(:, sortRow1) == r1) &... % extract all rows for matching z plane and...
            (infoND(:, sortRow2) == slotCube(r2)... % cube number
                           ), :); %#ok<AGROW>
    end
end

if flgMX
    ND = ND(1); % For MIP images use ND of the top plane
    ND{1}(:, 1) = 1:size( ND{1}(:, 1) );
end


end