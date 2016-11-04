function writeHeaderICE(fid, sH)

headerChar = repmat(char(0), 1, 256); % 2048 bytes of null characters
if isfield(sH, 'str')
    if length(sH.str) <= 256
        headerChar(1:length(sH.str)) = sH.str;
    else
        error('The header text cannot exceed 256 characters');
    end
end

headerVar = nan(256, 1); % 256 * 8 = 2048 bytes

addElementToHeader('dimX', 1); % 8 bytes each
addElementToHeader('dimY', 2);
addElementToHeader('dimZ', 3);
addElementToHeader('baseZ', 4);
addElementToHeader('stepZ', 5);
addElementToHeader('waitStage', 6);
addElementToHeader('waitPFS', 7);
addElementToHeader('tempIni', 8);
addElementToHeader('tempFin', 9);
addElementToHeader('tempSlope', 10);
addElementToHeader('holdIni', 11);
addElementToHeader('duration', 12);
addElementToHeader('prop', 13);
addElementToHeader('integ', 14);
addElementToHeader('voltage', 15);
addElementToHeader('coolheat', 16);
addElementToHeader('offsetDaq', 17);
addElementToHeader('offset1', 18);
addElementToHeader('offsetAt1', 19);
addElementToHeader('offset2', 20);
addElementToHeader('offsetAt2', 21);

% Overwrite the header for variables
% fid = fopen(pathICE, 'r+');
fseek(fid, 0, 'bof');
fwrite(fid, headerVar, 'double');

% Overwrite the header text
fwrite(fid, headerChar, 'char*1');

% fclose(fid);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function addElementToHeader(field, idx)
        if isfield(sH, field)
            headerVar(idx, 1) = sH.(field);
        end
    end

end