function killProcess(nameFile, indexKillSignal)

% Create a template file for memory mapping
pathFile = fullfile(tempdir, nameFile);

% Create the communications file if it is not already there.
if ~exist(pathFile, 'file')
    [f, msg] = fopen(pathFile, 'wb');
    if f ~= -1
        fwrite(f, zeros(64, 1), 'double');
        fclose(f);
    else
        error('MATLAB:neuroHeater:cannotOpenFile', ...
              'Cannot open file "%s": %s.', pathFile, msg);
    end
end
 
% Memory map the file.
memShared = memmapfile(pathFile, 'Writable', true, 'Format', 'double');
memShared.Data(indexKillSignal) = 1;

end