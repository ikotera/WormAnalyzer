classdef abstractManager < handle
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        am________________;
        nameStrain;
        nameFile;
        pathInput;
        pathFolder;
        listFiles;
        numFiles;
    end
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods
        function am = abstractManager()
        end
    end
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods
        
        function bool = readFiles(am, pathFolder, pathFile)
            am.pathInput = pathFolder;
            am.nameFile = pathFile;
            am.listFiles = rdir([pathFolder, '\**\', pathFile]);                          % Get a list of specified files
            am.numFiles = numel(am.listFiles);
            [am.pathFolder, ~, ~] = fileparts(am.listFiles(1).name);
            if am.numFiles < 1
                prt('No file to read.');
                bool = false;
                return
            else
                bool = true;
            end
        end        
%=================================================================================================================================
        function getStrainName(am)
            
            if isprop(am, 'behaviors') &&...
               isfield(am.behaviors.master{1}.metadata, 'status')               % If strain name (long) exists in metadata
                nameLong = am.behaviors.master{1}.metadata.status.nameSample;
            else                                                                % Else get it from the file name
                idxSl = strfind(am.pathFolder, '\');
                idxUb = strfind(am.pathFolder, '_');
                idxUb = idxUb(1) - 1;                                           % The first underbar
                idx = find(idxSl < idxUb, 1, 'last' );                          % The last slash left of the first underbar
                idxL = idxSl(idx) + 8;                                          % 8 charcters right of the slash
                nameLong = am.pathFolder(idxL:idxUb);
            end
            
            if strcmp(nameLong, '1.1-4')
                nameLong = 'N2';
            end
            
            br = strfind(nameLong, '(');
            if ~isempty(br)                                                     % If the strain name has bracket (ie, it's long)
                sp = strfind(nameLong, ' ');
                if isempty(sp)
                    sp = 0;
                else
                    sp = sp( find(sp < br - 1, 1, 'last' ) );                   % Find the right-most space left of '('
                end
                nameShort = nameLong(sp+1:br-1);                                % Extract a short name from the long name
                nameShort = strrep(nameShort, ' ', '');
                
            else                                                                % Else long name is short name
                nameShort = nameLong;
            end
            
            am.nameStrain = nameShort;

        end    
    end
end

%#ok<*MCNPN> 
    