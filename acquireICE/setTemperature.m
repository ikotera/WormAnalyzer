function setTemperature(s, T, offsetAtT1, T1, offsetAtT2, T2)
% The function sends 'set temperature' command to temperature controller at
% specified temperatrue t. s is serial port object.

% Safety feature
if ~isnumeric(T)
    disp('Temperature must be number.');
    return
elseif ~isscalar(T)
    disp('Temperature must be scalar.');
    return
elseif isnan(T)
    disp('Temperature must not be NaN.');
    return
elseif T < 10
    disp('Temperature is too low.');
    return
elseif T > 40
    disp('Temperature is too high.');
    return
end


% Adjust temperature with offsets
ot = T - offsetTemp(T, offsetAtT1, T1, offsetAtT2, T2);

% Temperature is multiplied by 100
t100 = round(ot * 100);

% Hex value of the above
thex = dec2hex(int32(t100));

% Append leading zeros to make it 8 digits
tzero = sprintf('%08s', thex);

% * + device number(00) + command (01) + temperature + checksum + CR
cmd = lower(['*0010', tzero, chksum(['0010', tzero]), '\n']);

while true
    pause(0.5);
    status = get(s,'TransferStatus');
    switch status
        case {'write', 'read&write'}
        otherwise
            break
    end
    prt('Serial Transfer Status by Temperature:', status);
end

fprintf(s, cmd, 'async');

% Read return string from the controller
% ret = readSerial(s);

% disp(['Sent command: ', cmd]);
% disp(['Received command: ', ret]);
% T = hex2dec(ret(7:9)) / 100;
% disp(['Temperature set to ', num2str(t), 'C degrees.']);

end
