function commandWindowOnly

dtp = com.mathworks.mde.desk.MLDesktop.getInstance;

% if ~exist('layout', 'var')
%     layout = 'minimum';
%     flgMin = true;
% else
%     flgMin = false;
% end
% 
% dtp.restoreLayout(layout);
% sleep(100);
% 
% if flgMin
%     com.mathworks.mde.desk.MLDesktop.getInstance.getMainFrame.hide;
% else
%     com.mathworks.mde.desk.MLDesktop.getInstance.getMainFrame.show;
% end



% cw = dtp.getClient('Command Window');




 

% mde = com.mathworks.mde.desk.MLDesktop.getInstance;


cw = dtp.getClient('Command Window');

dtp.getInstance.initMainFrame(0,0,1) % no restore, minimized

pause(1);

% dtp.setClientDocked(cw,1);
dtp.setClientDocked(cw,0);

pause(1);

com.mathworks.mde.desk.MLDesktop.getInstance.getMainFrame.hide;

% 
% -r "com.mathworks.mde.desk.MLDesktop.getInstance.closeCommandWindow; run('C:\<a long path here>\mfile.m');"
% 
% system('matlab -nosplash -nodesktop &');

end