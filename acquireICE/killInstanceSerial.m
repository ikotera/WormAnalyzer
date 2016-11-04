% Create a template file for memory mapping
nameFile = fullfile(tempdir, 'memSharedSerial.dat');

% Create the communications file if it is not already there.
if ~exist(nameFile, 'file')
    [f, msg] = fopen(nameFile, 'wb');
    if f ~= -1
        fwrite(f, zeros(1, 64), 'double');
        fclose(f);
    else
        error('MATLAB:neuroHeater:cannotOpenFile', ...
              'Cannot open file "%s": %s.', nameFile, msg);
    end
end
 
% Memory map the file.
memSharedSerial = memmapfile(nameFile, 'Writable', true, 'Format', 'double');
memSharedSerial.Data(2) = 1;