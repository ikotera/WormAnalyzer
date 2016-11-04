function copyHeaderICE(pathFrom, pathTo)

fidFrom = fopen(pathFrom, 'r');

% Read header information
fseek(fidFrom, 0, 'bof');
tempHeader = fread(fidFrom, 256, 'double');
fclose(fidFrom);

% Overwrite the header information
fidTo = fopen(pathTo, 'r+');
fseek(fidTo, 0, 'bof');
fwrite(fidTo, tempHeader, 'double');
fclose(fidTo);

end