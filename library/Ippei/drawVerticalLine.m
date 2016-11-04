function hVL = drawVerticalLine(hAxis, x)
% function hVL = drawVerticalLine(hAxis, x)
%
% Draws a vertical line on a specified axis.
% 
% Example:
% if ishandle(hVL)
%     delete(hVL); % Deletes previous vertical line if exists
% end
% hVL = drawVerticalLine(hAxis, x);

linetype = 'r:';
hold(hAxis, 'on');
y = get(hAxis, 'ylim');
hVL = plot(hAxis, [x x], y, linetype);
hold(hAxis, 'off');

end