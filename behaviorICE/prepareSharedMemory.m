function s = prepareSharedMemory(s)

% s.dimX = 2560;
% s.dimY = 2160;
s.sizeImage = s.dimX * s.dimY;
s.sizeDouble = 260; % 4 + 256
s.sizeInt16 = 2560; % 2048 + 256 + 256
s.sizeBuffer = 100;

if s.depthBit == 8
    s.iniMat = zeros(s.sizeImage / 2 + s.sizeDouble * 4 + s.sizeInt16, s.sizeBuffer, 'int16'); % uint8 is half the size of uint16
    s.format = {'double', [1 1], 'readyMaster';...
        'double', [1 1], 'readySlave';...
        'double', [1 1], 'destroySlave';...
        'double', [1 1], 'frame';...
        'double', [256 1], 'headerNum';...
        'int16', [2048 1], 'headerChar';...
        'int16', [256 1], 'nameFile';...
        'int16', [256 1], 'reserved';...
        'uint8', [s.sizeImage s.sizeBuffer], 'image'}; % 8 bit
    s.formatFile = 'int16';
    
elseif s.depthBit == 16
    
    s.iniMat = zeros(s.sizeImage + s.sizeDouble * 4 + s.sizeInt16, s.sizeBuffer, 'int16');
    s.format = {'double', [1 1], 'readyMaster';...
        'double', [1 1], 'readySlave';...
        'double', [1 1], 'destroySlave';...
        'double', [1 1], 'frame';...
        'double', [256 1], 'headerNum';...
        'int16', [2048 1], 'headerChar';...
        'int16', [256 1], 'nameFile';...
        'int16', [256 1], 'reserved';...
        'int16', [s.sizeImage s.sizeBuffer], 'image'}; % 16 bit
    s.formatFile = 'int16';
else
    error('Bit depth of the image has to be 8 or 16.');
    
end