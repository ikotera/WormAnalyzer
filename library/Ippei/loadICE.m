%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                loadICE.m                                %
%                      Oct. 29, 2013 by Ippei Kotera                      %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Faster alternative to openICE function. Use loadICE whenever loading
% speed is a concern.

function imageStack = loadICE(firstFrame, numFrames, fid, dimX, dimY)

% Reset the position
fseek(fid, 0, 'eof');
fseek(fid, 0, 'bof');

if dimX == 2048
    depthByte = 1;
else
    depthByte = 2;
end

% Calculate the byte position of the first frame and move it to there
firstByte = 4096 + (firstFrame - 1) * (dimX * dimY * depthByte);
fseek(fid, firstByte, 'bof');

if dimX == 512
    % Read the entire stack as a line
    dataLine = fread(fid, dimY * dimX * numFrames, '*uint16');
    
    % Then reshape the line to a 3D image matrix
    imageStack = reshape(dataLine, dimY, dimX, numFrames);
elseif dimX == 2048
    dataLine = fread(fid, dimY * dimX * numFrames, '*uint8');
    imageStack = permute( reshape( dataLine, dimY, dimX, numFrames ), [2 1 3]);
%     imageStack = im(83:1:end-30, 197:1:end-316, :);
    
elseif dimX == 2160
    dataLine = fread(fid, dimY * dimX * numFrames, '*uint16');
    im = permute( reshape( dataLine, dimY, dimX, numFrames ), [2 1 3]);
    imageStack = im(83:1:end-30, 197:1:end-316, :);
else
    error('Specified dimensions are not supported');
end

end

