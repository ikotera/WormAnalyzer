function deconvBatch(pathICE)

% -Dependendies: Miji.m, rdir.m, prt.m, deconvij.m, openICE, readHeaderICE, writeICE.m,
% copyHeaderICE.m, checkPathType.m


% Clear all dynamic java paths
djp = javaclasspath('-dynamic');
if ~isempty(djp)
    javarmpath(djp{:});
end

Miji;

flgNetwork = 0;
tempFolder = 'C:\tempDecon';

type = checkPathType(pathICE);

switch type
    case {'Network', 'UNC'}
        flgNetwork = 1;
    case {'Invalid', 'Non-rooted'}
        error('The input path is not valid');
end

pathPSF = '\\101.101.1.113\data\Ippei\PSF\psfG20.tif';

for idx = 1:8
    psf(:, :, idx) = imread(pathPSF, 'Index', idx); %#ok<AGROW>
end

% Get a list of ice files in the folder and subfolders
listICE = rdir([pathICE, '\**\*.ice']);
numICEFiles = numel(listICE);
fdel = false(numICEFiles, 1);
for l = 1:numICEFiles
    [~, nm, ~] = fileparts(listICE(l).name); % name of the ice file
    if ~strcmp(nm(6), '_') % if the file name has infix after Img-N such as 'R'
        fdel(l) = true; % raise a delete flag
    end
end
listICE(fdel) = []; % remove the file name
numICEFiles = numel(listICE);

%% Deconvolve all the ice files in the folder and subfolders

tTotal = tic;
for nif = 1:numICEFiles
    
    [namePath, nF, nE] = fileparts(listICE(nif).name);
    nameFile = [nF, nE];
    channelNum = nameFile(5); % get channel number (ie, 1, 2, 3, or 4)

    nameFileNew = [nF(1:5), 'RD', nF(6:end), nE];
    
    if flgNetwork
        if exist(tempFolder, 'dir')
            rmdir(tempFolder, 's');
        end
        mkdir(tempFolder);
        namePathNet = namePath;
        namePath = tempFolder;
        prt(['Downloading ', nameFile, ' from network...']);
        copyfile([namePathNet, '\', nameFile], tempFolder);

    end
    
%     if ~exist([namePath, '\deconv'], 'dir')
%         mkdir([namePath, '\deconv']);
%     end
    
    % Header info
    Str = readHeaderICE([namePath, '\', nameFile]);
    dimX = Str.dimX;
    dimY = Str.dimY;
    dimT = Str.dimT;
    dimZ = Str.dimZ / Str.stepZ;
    dimTP = dimT / dimZ;
    
    % Open a new ice file
    fid = writeICE(nan, nan, [namePath, '\', nameFileNew], nan, []);
    
    % Preallocate shift variables
    if strcmp(channelNum, '1')
        shiftX = zeros(dimTP, 1);
        shiftY = zeros(dimTP, 1);
    end
    
    for tp = 1:dimTP
        
        % Load a stack
        stack = openICE( (tp - 1) * dimZ + 1, dimZ, [namePath, '\', nameFile]);
        
        prt('Deconvolving ', [namePath, '\', nameFile], ': T = ', tp, '/', dimTP);
        tic;
        % Deconvolution in ImageJ
        stackDecon = deconvij(stack, psf, 7, 8, 1);
%         stackDecon = zeros(dimX, dimY, dimZ); % Dummy data for testing
        toc;
        
        % Prepare template or cropped image for image registration
        if tp == 1
            template = stackDecon(:, :, 1);
        else
            imgCrop = stackDecon(129:384, 129:384, 1);
        end
        
        % Find shift values if it's the first channel
        if strcmp(channelNum, '1')
            if tp > 1
                [shiftX(tp), shiftY(tp)] = findImageOffset(template, imgCrop);
            end
        end
        
        stackDecon = shiftStack(stackDecon, shiftY(tp), shiftX(tp));
        
        % Write to a new ice file
        line = reshape(stackDecon, 1, dimX * dimY * dimZ);
        writeICE(fid, line);
        
    end
    
    fclose(fid);
    
    % Copy the header
    copyHeaderICE([namePath, '\', nameFile], [namePath, '\', nameFileNew]);
    
    if flgNetwork
%         if ~exist([namePathNet, '\deconv'], 'dir')
%             mkdir([namePathNet, '\deconv']);
%         end
        prt(['Uploading ', nameFileNew, ' back to network...']);
        copyfile([namePath, '\', nameFileNew], [namePathNet, '\']);
    end
    
end

if flgNetwork
    if exist(tempFolder, 'dir')
        rmdir(tempFolder, 's');
    end
end

%% Copy all the mat files to deconv folder
% listMAT = rdir([pathICE, '\**\*.mat']);
% numMATFiles = numel(listMAT);
% 
% for nmf = 1:numMATFiles
%     [namePath, nameFile, nameExt] = fileparts(listMAT(nmf).name);
% 
%     copyfile(listMAT(nmf).name, [namePath, '\deconv\', nameFile, nameExt]);
% end

prt('%0.1f',...
    'Deconvolution complete: Total time is',...
    toc(tTotal), 'seconds (',...
    toc(tTotal)/60, 'minutes or',...
    toc(tTotal)/3600, 'hours ).');

MIJ.exit;

end