function instanceDisk

% dbstop in instanceDisk 102;

% Specify names of template files for memory mapping
nameFileHeader{1} = fullfile(tempdir, 'memSharedHeader1.dat');
nameFileHeader{2} = fullfile(tempdir, 'memSharedHeader2.dat');
nameFileImage{1} = fullfile(tempdir, 'memSharedImage1.dat');
nameFileImage{2} = fullfile(tempdir, 'memSharedImage2.dat');

for ind = 1:2
    % Create a template file for memory mapping
    memSharedHeader{ind} = memmapfile(nameFileHeader{ind}, 'Writable',...
        true, 'Format', 'double'); %#ok<*AGROW>
    
    % Create memory map for images
    memSharedImage{ind} = memmapfile(nameFileImage{ind},...
        'Writable', true, 'Format', 'uint16'); %#ok<AGROW>
    
    % Slave is ready (memory mapping)
    memSharedHeader{ind}.Data(2, 1) = 1;


end



% Wait until master's header is ready
while true
    if memSharedHeader{1}.Data(1, 1) == 0 &&...
            memSharedHeader{2}.Data(1, 1) == 0
        break;
    end
end

% Number of predicted frames
numFrames(1) = memSharedHeader{ind}.Data(4, 1);

% Preallocate infoND
infoND = nan(numFrames(1), 4, 'double');


for ind = 1:2
    % Get names of ice files from shared memory
    nameFileICE{ind} = memSharedHeader{ind}.Data(101:356, 1);
    nameFileICE{ind}(isnan(nameFileICE{ind})) = [];
    nameFileICE{ind} = char(nameFileICE{ind}');
    
    % Get header information
    hdrNum = memSharedHeader{ind}.Data(401:656, 1);
    hdrNum(isnan(hdrNum)) = [];
    
    hdrChr = memSharedHeader{ind}.Data(701:2748, 1);
    hdrChr(isnan(hdrChr)) = [];
    hdrChr = char(hdrChr');
    
    % Write header information to the ice files on disk
    fidImg(ind) = writeICE(nan, nan, nameFileICE{ind}, hdrNum', hdrChr); %#ok<*NASGU>
end

framePrev(1:2) = 0;

while true
    
    % Get frame numbers from the shared memory
    frame(1) = memSharedHeader{1}.Data(1, 1);
    frame(2) = memSharedHeader{2}.Data(1, 1);
    
    % If master's images are ready, then...
    if frame(1) >= 1 && frame(2) >= 1 && frame(1) == frame(2)
        
        % If current frame number is larger than previous (meaning the
        % images are updated)
        if frame(1) > framePrev(1)
          % ND information
          infoND(frame, 1) = frame;
          infoND(frame, 2) = memSharedHeader{1}.Data(5, 1); % frameZ
          infoND(frame, 3) = memSharedHeader{1}.Data(6, 1); % posZ
          infoND(frame, 4) = memSharedHeader{1}.Data(7, 1); % elapsed time
          
            for ind = 1:2
                % Get image data from the shared memory
                ln(:, ind) = memSharedImage{ind}.Data;
                
                % Write image data to the file
                writeICE(fidImg(ind), ln(:, ind));
                
                % Image in the shared memory has been read
                memSharedHeader{ind}.Data(1, 1) = 0;

            end
            % Current frame number to the previous frame
            framePrev = frame;
        end
        
    end
    
    % If auto-destruct sequence is activated by the master
    if memSharedHeader{1}.Data(3, 1) == 1;
      [nameFolder, nameFile, ~] = fileparts(nameFileICE{1});
      pathMat = [nameFolder, '\infoND_', nameFile(7:17), '.mat'];
      save(pathMat, 'infoND');
        fclose(fidImg(1));
        fclose(fidImg(2));
        exit;
    end
    
    java.lang.Thread.sleep(10);
    
end



