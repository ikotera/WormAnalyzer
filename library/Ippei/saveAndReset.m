

% try
%     dbquit('all');
%     
%     pause(0.1);
% catch e1
%     disp(e1)
%     try
%         
%         evalin('base', 'dbquit(''all'')');
%     catch e2
%         
%         disp(e2);
%     end
% end

dc = matlab.desktop.editor.getAll;
if any([dc.Modified])
    dc(1,[dc.Modified]).save;
end

clear all
clc;
