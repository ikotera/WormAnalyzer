function sH = readHeaderICE(pathICE)


fid = fopen(pathICE, 'r');

% Read the header information
fseek(fid, 0, 'eof');
lastByte = ftell(fid);
fseek(fid, 0, 'bof');

% First 2 variables of number header
sH.dimX = fread(fid, 1, 'double'); % 8 bytes
sH.dimY = fread(fid, 1, 'double'); % 8 bytes
sH.dimZ = fread(fid, 1, 'double'); % 8 bytes
sH.baseZ = fread(fid, 1, 'double'); % 8 bytes
sH.stepZ = fread(fid, 1, 'double'); % 8 bytes
sH.depthBit = fread(fid, 1, 'double'); % 8 bytes
sH.waitPFS = fread(fid, 1, 'double'); % 8 bytes
sH.tempIni = fread(fid, 1, 'double'); % 8 bytes
sH.tempFin = fread(fid, 1, 'double'); % 8 bytes
sH.tempSlope = fread(fid, 1, 'double'); % 8 bytes
sH.holdIni = fread(fid, 1, 'double'); % 8 bytes
sH.duration = fread(fid, 1, 'double'); % 8 bytes
sH.prop = fread(fid, 1, 'double'); % 8 bytes
sH.integ = fread(fid, 1, 'double'); % 8 bytes
sH.voltage = fread(fid, 1, 'double'); % 8 bytes
sH.coolheat = fread(fid, 1, 'double'); % 8 bytes
sH.offsetDaq = fread(fid, 1, 'double'); % 8 bytes
sH.offset1 = fread(fid, 1, 'double'); % 8 bytes
sH.offsetAt1 = fread(fid, 1, 'double'); % 8 bytes
sH.offset2 = fread(fid, 1, 'double'); % 8 bytes
sH.offsetAt2 = fread(fid, 1, 'double'); % 8 bytes

if sH.depthBit == 8
    depthByte = 1;
elseif sH.depthBit == 16
    depthByte = 2;
else
    depthByte = 2; % For compatibility
end


% Skip (256 - 21) * 8 bytes (space reserved for future use)
fread(fid, 235, 'double');

% Read string header for 256 * 8 bytes = 2048 bytes
sH.str = fread(fid, 256, '*char')';

% Size of each frame in bytes (Each uint16 pixel is 2-byte long)
byteSizeFrame = sH.dimX(1) * sH.dimY(1) * depthByte;

% The size of the ice file header is 2048 + 2048 = 4096 bytes
byteSizeImageStack = lastByte - 4096;

% Number of frames
sH.dimT = round(byteSizeImageStack / byteSizeFrame);

fclose(fid);


end