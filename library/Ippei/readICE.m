function [hdrNum, hdrChr, img] = readICE(fid, ishdr, dimX, dimY)


if ishdr
    hdrNum = fread(fid, 256, 'double');
    hdrChr = fread(fid, 2048, '*char')';
    img = nan;
else
    l = fread(fid, dimX * dimY, '*uint16');
    img = reshape(l, dimX, dimY);
    hdrNum = nan;
    hdrChr = nan;
    
end

end