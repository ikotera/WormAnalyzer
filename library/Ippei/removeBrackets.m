function removeBrackets(pathInput)
% The function removes the first square brackets and any string inbetween
% them from a file name.

[namePath, nameFile, ext] = fileparts(pathInput);

bracketR = strfind(nameFile, ']');

% Return if no square bracket is found
if isempty(bracketR)
    disp('No square bracket!');
    return;
elseif bracketR(1) >= length(nameFile)
    disp('File name cannot end with a square bracket');
    return;
% Otherwise consider only the first bracket
else
    bracketR = bracketR(1);
end

% If the character next to the bracket is space or underscore, then remove
% it along with the brackets and their content
if any(strcmp(nameFile(bracketR + 1), {' ', '_'}))
    nameFile = nameFile(bracketR + 2:end);
else
    nameFile = nameFile(bracketR + 1:end);
end

pathNew = [namePath, '\', nameFile, ext];

% Rename the file using movefile function with force option
pn = java.io.File(pathNew);
bl = java.io.File(pathInput).renameTo(pn);

if bl
    % movefile(pathInput, pathNew, 'f');
    disp(['File renamed: ', pathNew]);
else
    error(['File was not renamed: ', pathNew]);
end


end