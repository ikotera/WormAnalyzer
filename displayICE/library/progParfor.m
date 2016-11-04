function numAnalyzed = progParfor(currentLoop, dirCount)
% This function writes a zero-size file to a directory and counts the number of
% files in that directory. Use it to count number of current iteration in
% parfor loops.

filename = sprintf('%05u', currentLoop);

fid = fopen([dirCount, '\', filename, '.cnt'], 'W+');

fclose(fid);

list = dir(dirCount);

numAnalyzed = numel(list) - 2;

end