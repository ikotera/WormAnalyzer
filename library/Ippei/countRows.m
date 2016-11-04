function numberOfLines = countRows(nameFile)

fid = fopen(nameFile);
allText = textscan(fid,'%s','delimiter','\n');
numberOfLines = length(allText{1});
fclose(fid);

return