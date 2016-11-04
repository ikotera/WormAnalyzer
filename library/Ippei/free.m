function bool = free(obj, verbose)

if ~exist('errcheck', 'var')
    verbose = false;                                                        % Verbose mode for debugging
end

try
    if isempty(obj)
        error('The object is empty.');
    end
    delete(obj);                                                            % Try to delete the object
    bool = true;
catch err
    if verbose
        str = inputname(1);                                                 % Try to find the name of the object in caller's space
        nameObj = 'unidentified';
        if isempty(str)                                                     % If not found: (as in the case of struct)
            nameVars = evalin('caller', 'whos;');                           % Collect names of all the variables in caller's space
            nameStructs = cell(size(nameVars)); s = 1;
            for v = 1:numel(nameVars)
                if strcmp(nameVars(v).class, 'struct')
                    nameStructs{s} = nameVars(v).name;                      % Pick only the structure variables
                    s = s + 1;
                end
            end
            nameStructs(cellfun(@isempty, nameStructs)) = [];               % Delete empty cells
            
            flgBreak = false;
            if ~isempty(nameStructs)
                for t = 1:numel(nameStructs)                                % In all the structures,
                    fl = evalin('caller', ['fieldnames(', nameStructs{t}, ');']);
                    for f = 1:numel(fl)                                     % Find matching handle in all the fields
                        h = evalin('caller', [nameStructs{t}, '.', fl{f}]);
                        if isnumeric(h) && isscalar(h) && ~isempty(h) && ~isempty(obj) && h == obj
                            nameObj = [nameStructs{t}, '.', fl{f}];
                            flgBreak = true;
                            break;
                        end
                    end
                    if flgBreak
                        break;
                    end
                end
            end
        else
            nameObj = str;
        end
        % Print the error with the name of the object
        prt('Could not free ''\ns', nameObj, '\ns''.', err.message, '[', err.stack(2).name, 'at line', err.stack(2).line, ']');
        bool = false;
    end
end

end