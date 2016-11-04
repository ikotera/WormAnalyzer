function tif2ice(pathTif)

tAll = tic;



disp('Reading tiff headers...');


info = imfinfo(pathTif);
zDim = numel(info);
xDim = info(1, 1).Width;
yDim = info(1, 1).Height;

zDim = 10000;

%% Create ice files
for zi = 1:2
    [pathFile, nameFile, ~] =...
        fileparts(pathTif);
    nameFileNew{1} = ['Img-', nameFile];
    pathICE = [pathFile, '\', nameFileNew{1}, '.ice'];
    
    % Write header information
    fid = writeICE(nan, nan, pathICE, [xDim yDim],...
        'Converted from tif stack by tif2ice');
end



%% Convert tif to ice



% Pre-allocate im
im = zeros(yDim, xDim, zDim, 'uint16');



tic;
for zs = 1:zDim
    
    
    % Open tif stack with imfinfo output argument (fastest in
    % 2012b)
%     im = imread(pathTif, 'Index', zs,...
%         'Info', info);
    
    im = imread(pathTif, 'Index', zs);
    
    ln = reshape(im, 1, yDim*xDim);
    
    % Write image data to the file 1
    writeICE(fid, ln);
    
    disp(zs);
    
end

toc;

    fclose(fid);

    
disp(['Total time is ', num2str(toc(tAll)), ' seconds.']);

end