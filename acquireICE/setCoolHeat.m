function setCoolHeat(s, mode)
% The function sends 'set temperature' command to temperature controller at
% specified temperatrue t. s is serial port object.

% Safety feature
if ~ischar(mode)
    disp('Input argument must be string.');
    return

end
if ~(strcmp(mode, 'cool')||strcmp(mode, 'heat'))
    disp('Input argument must be eiter cool or heat.');
    return
end

switch mode
    case 'cool'
        thex = dec2hex(int32(0));
        
    case 'heat'
        thex = dec2hex(int32(1));
end

% Append leading zeros to make it 8 digits
tzero = sprintf('%08s', thex);

% * + device number(00) + command (01) + temperature + checksum + CR
cmd = lower(['*0018', tzero, chksum(['0018', tzero]), '\n']);

while true
    pause(0.5);
    status = get(s,'TransferStatus');
    switch status
        case {'write', 'read&write'}
        otherwise
            break
    end
    prt('Serial Transfer Status by Coolheat:', status);
end

fprintf(s, cmd, 'async');

% Read return string from the controller
% rs = readSerial(s);

% disp(['Sent command: ', cmd]);
% disp(['Received command: ', ret]);
% mode = hex2dec(ret(7:9)) / 100;
% disp(['Temperature set to ', num2str(t), 'C degrees.']);
% 
% if rs(9) == '0'
%     ret = 'cool';
% elseif rs(9) == '1'
%     ret = 'heat';
% else
%     ret = 'error';
% end

end
