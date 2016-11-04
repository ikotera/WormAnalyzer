function img = readImage(t, dimT, z, dimZ, path, ND, type, imgRAM, imgMap)
% Reads from an image from the ICE file given by its path
% that corresponds to zth level and tth time point, given that it has dimZ
% z levels

% If it's RAM image mode, then simply copies an image plane from image
% stack in RAM (130829, Ippei).

% Make sure frame number stays within the range (Changed to ND method to
% deal with 3D images, 130827 by Ippei)
if(t > dimT / dimZ)
    t = dimT / dimZ;
elseif(t <  1)
    t = 1;
end
index = ND{z}(t, 1);

% index = (t - 1) * dimZ + z;

if nargin < 7
    type = 'uint16';    % Default type
end

switch type
    case 'double'
        img = openICE_double(index, 1, path);
    case 'uint16'
        img = openICE(index, 1, path);
    case 'RAM'
        img = imgRAM(:, :, index);
    case 'map'
        img = imgMap.Data.img(:, :, index);
end



end