function numberSession = getSessionNumber()


[~, cmdout] = dos('C:\\PSTools\psexec \\101.101.1.46 tasklist /FI "IMAGENAME EQ explorer.exe" /FO list');


[~, cmdout] = dos('tasklist /FI "IMAGENAME EQ explorer.exe" /FO list');
    
    anch = strfind(cmdout, 'Session#');
    anch = anch(1);
    numberSession = cmdout(anch + 14);
end
