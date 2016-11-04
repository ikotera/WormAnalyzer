function lenFraction = prtprg(iteration, total, lenFraction, message)

% lenFraction = prtprg(iteration, total, lenFraction, message)
% 
% Text based progress monitor.
% 
% Example usage:
% j = 10;
% lf = 0;
% for i=1:j
% %     doSomething;
%     lf = prtprg(i, j, lf, 'Doing something:');
%     pause(0.2); 
% end

if ~exist('message', 'var')
    message = 'In progress:'; % Default message
end

fraction = round(iteration / total * 100);

if lenFraction == 0
    fprintf(1, [message, ' ', num2str(fraction), ' %%']);
else
    fprintf(1, repmat('\b', 1, lenFraction + 2)); % Backspace lenFranction times
    fprintf(1, [num2str(fraction), ' %%']);
end

if iteration == total
    fprintf(1, '\n');
end

lenFraction = length(num2str(fraction));


end