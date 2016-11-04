%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                openICE.m                                %
%                      Nov. 27, 2012 by Ippei Kotera                      %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



function imageStack = openICE(firstFrame, numFrames, filePathImageStack)

% Open image stack in dat format
fid = fopen(filePathImageStack, 'r');

% Read a part of the header for x and y dimensions
fseek(fid, 0, 'eof');
fseek(fid, 0, 'bof');
xDimStack = fread(fid, 1, 'double'); % 4 bytes
yDimStack = fread(fid, 1, 'double'); % 4 bytes

%Allocating Memory
imageStack = zeros(yDimStack, xDimStack, numFrames, 'uint16');

% Calculate the byte position of the first frame and move it to there
firstByte = 4096 + (firstFrame - 1) * (xDimStack * yDimStack * 2);
fseek(fid, firstByte, 'bof');

for n = 1:numFrames
    
    % Use fread to skip 25 bytes of frame header (faster than fseek)
%     fread(fid, 3, 'double'); % 24 bytes
%     fread(fid, 1, 'uint8'); % 1 byte
    
    % Read the entire frame as a vector
    vec = fread(fid, yDimStack * xDimStack, '*uint16');
    
    % Then reshape the vector to an image matrix
    image = reshape(vec, yDimStack, xDimStack);
    
    % Build an image stack
    imageStack(:, :, n) = image;
    
end

fclose(fid);

end

