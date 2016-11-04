function ice2tif(pathICE, numStack)

[pathFile, nameFile, ~] = fileparts(pathICE);

pathTif = [pathFile, '\', nameFile, '.tif'];

% Dimension calculations changed to ICE header, 130827 by Ippei
Str = readHeaderICE(pathICE);
% dimZ = Str.dimZ / Str.stepZ;

if exist('numStack', 'var')
    dimT = numStack;
else
    dimT = Str.dimT;
end

img = openICE(1, dimT, pathICE);

% outputFileName = 'img_stack.tif';
for t = 1: dimT
    imwrite(img(:, :, t), pathTif, 'WriteMode', 'append', 'Compression','none');
end

end

