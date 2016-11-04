


% Specify names of template files for memory mapping
nameFileHeader = fullfile(tempdir, 'memSharedHeader1.dat');


% Create a template file for memory mapping
memSharedHeader = memmapfile(nameFileHeader, 'Writable',...
    true, 'Format', 'double'); %#ok<*AGROW>


memSharedHeader.Data(3) = 1;