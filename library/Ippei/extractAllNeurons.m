function extractAllNeurons(pathInput)
% extractAllNeurons(pathInput);
%
% This function accepts a file path from Windows context menu (or else), and passes it on to neuronManager. Use the
% neuronManger class to read and sort labelled neurons. Then it calls scrollablePlots function for GUI.
%=================================================================================================================================
nm = neuronManager;
%=================================================================================================================================
nm.flgMergeLR = true;
nm.flgMeanLR = false;
nm.modeNormalization = 'bottom';
nm.flgSynchLaser= true;
% nm.selectedNeurons = {'RIS'; 'AVD';'AVA';'SMDV';'AVB';'SMDD';'RME';'RMDV'};
% nm.selectedNeurons = {'AIY'};
%=================================================================================================================================
b = nm.readFiles(pathInput, 'neurons.mat'); if ~b, return, end
rateSampling = 1;
b = nm.parseFiles(rateSampling); if ~b, return, end
nm.sortNeurons;
nm.getStats;
nm.getLaserOutput;
nm.saveStats;
nm.saveObject;
%=================================================================================================================================
scrollablePlots(nm);
