function setVoltage(s, v)
% The function sends 'set voltage' command to temperature controller at
% specified temperatrue t. s is serial port object.

% Safety feature
if ~isnumeric(v)
    disp('Voltage must be number.');
    return
elseif ~isscalar(v)
    disp('Voltage must be scalar.');
    return
elseif isnan(v)
    disp('Voltage must not be NaN.');
    return
elseif v < 2
    disp('Voltage is too low.');
    return
elseif v > 10
    disp('Voltage is too high.');
    return
end

% voltage is multiplied by 100
v1000 = v * 1000;

% Hex value of the above
thex = dec2hex(int32(v1000));

% Append leading zeros to make it 8 digits
tzero = sprintf('%08s', thex);

% * + device number(00) + command (01) + voltage + checksum + CR
cmd = lower(['*0016', tzero, chksum(['0016', tzero]), '\n']);

while true
    status = get(s,'TransferStatus');
    switch status
        case {'write', 'read&write'}
        otherwise
            break
    end
    prt('Serial Transfer Status:', status);
    pause(0.1);
end

fprintf(s, cmd, 'async');

% Read return string from the controller
% ret = readSerial(s);

% disp(['Sent command: ', cmd]);
% disp(['Received command: ', ret]);
% setV = hex2dec(ret(7:9)) / 1000;
% disp(['voltage set to ', num2str(t), 'C degrees.']);

end
