function fid = writeICE(fid, line, nameFile, hdrNum, hdrChr)

    if isnan(fid)
        tempNum = nan(256, 1); % 256 * 8 = 2048 bytes       
        tempChr = repmat(char(0), 1, 2048); % 2048 bytes
        
        tempNum(1:length(hdrNum)) = hdrNum;
        tempChr(1:length(hdrChr)) = hdrChr;
        hdrNum = tempNum;
        hdrChr = tempChr;

        fid = fopen(nameFile, 'W');
        fwrite(fid, hdrNum, 'double');
        fwrite(fid, hdrChr, 'char*1');
    else

        fwrite(fid, line, 'uint16'); % 512 * 512 * 2 = 524,288 bytes
    end
    
end