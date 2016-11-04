function extractAll(path)
% Determines wether to run extractAllNeurons or extractAllWorms

W = numel( rdir([path, '\**\worms.mat']) );
N = numel( rdir([path, '\**\neurons.mat']) );

if W && ~N
    extractAllWorms(path);
elseif ~W && N
    extractAllNeurons(path);
elseif ~W && ~N
    warning('This folder contains neither worms.mat nor neurons.mat');
else
    warning('Both worms.mat and neurons.mat exist in the same folder and/or its subfolders.');
end

end

