%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                           loadIcePartial.m                              %
%                      Jun. 02, 2015 by Ippei Kotera                      %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Faster alternative to openICE function. Use loadICE whenever loading
% speed is a concern.

function ROI = loadIcePartial(fid, dimX, dimY, dimZ, dimT, X, Y, Z, W, H)

% Reset the position
fseek(fid, 0, 'eof');
fseek(fid, 0, 'bof');

if dimX == 2048
    byte = 1;
else
    byte = 2;
end

X = X - 1;
Y = Y - 1;
W = W + 1;
H = H + 1;

prec = [num2str(W), '*uint16'];
M = zeros(W * H, dimT, 'uint16');

% Calculate the byte position of the first frame and move it to there
% firstByte = 4096 + (firstFrame - 1) * (dimX * dimY * depthByte);
firstByte = 4096;
fseek(fid, firstByte, 'bof');


for t = 1:dimT
           
    fseek(fid, (Z - 1) * dimX * dimY * byte, 'cof');            % Skip to the specified Z plane
    fseek(fid, Y * dimX * byte, 'cof');                         % Skip to the top of ROI                    
    fseek(fid, X * byte, 'cof');                                % Skip to the left of ROI for the first line
    
%     for h = 1:H                                               % Read a line (W) and skip the rest of line (dimX - W - X),
%         s = (h-1)*W+1; e = s+W-1;                             % and skip to the left of ROI for the next line (X).
%         M(s:e, t) = fread(fid, W, '*uint16');                 % Combining above yields (dimX - W).
%         fseek(fid, (dimX - W) * byte, 'cof');                 % Vectorized version of the same algo is below (~6 times faster).                                                    
%     end                                                         

    M(:, t) = fread(fid, W * H, prec, (dimX - W) * byte);       % prec should be 'W*uint16' where W is size of each read
    
    fseek(fid, (-X + (dimY - Y - H) * dimX) * byte, 'cof');     % Go back extra X from the last line (-X),  
    fseek(fid, (dimZ - Z) * dimX * dimY * byte, 'cof');         % Skip to the last Z plane
%     prt(ftell(fid));
end

ROI = reshape(M, W, H, dimT);

end



