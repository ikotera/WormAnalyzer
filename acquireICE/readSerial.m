function chr = readSerial(s)
% The function reads string data recieved from Oven Industries' temperature
% controller through serial port.

% chr = '';
% temp = '';

% Timeout for reading buffer is set to 2 seconds
% set(s,'Timeout',2);

% Read chracters from buffer until '^' is reached


chr = fscanf(s, '%s', 12);

% chr = fread(s, 12, 'char');

% while isempty(temp) || temp ~= '^'
%     temp = fscanf(s, '%c', 1);
%     % Terminate the loop if no readout after 1st try
%     if isempty(temp)
%         break
%     end
%     chr = [chr temp];
% end

end