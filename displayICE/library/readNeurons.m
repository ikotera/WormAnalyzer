function [ cellOut ] = readNeurons( cellIn, field )
% Extracts field content of all the nested structures inside a cell array

sizeCell1 = numel(cellIn);
cellOut = cell(1, sizeCell1);

for ii = 1:sizeCell1
    sizeCell2 = numel(cellIn{ii});
    for jj = 1:sizeCell2
        cellOut{ii}{jj, 1} = cellIn{ii}{jj}.(field);
    end
    
end

end
