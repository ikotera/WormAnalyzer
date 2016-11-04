function memoryShared = createSharedMemory(memoryShared, nameFile, initialMatrix, format, formatFile)

if nargin <= 3
    format = 'double';
    formatFile = format;
end


% Create shared memory for a new process of MATLAB (serial communication)
if ~isobject(memoryShared)
    pathFile = fullfile(tempdir, nameFile);
    
    % Create the communication file if it is not already there.
    if ~exist(pathFile, 'file')
        [fid, msg] = fopen(pathFile, 'wb');
        if fid == -1
            error('MATLAB:acquireICE:cannotOpenFile',...
                'Cannot open file "%s": %s.', pathFile, msg);
        end
        fwrite(fid, initialMatrix, formatFile); fclose(fid);
    end
    
    memoryShared = memmapfile(pathFile, 'Writable', true, 'Format', format);
    
end

end