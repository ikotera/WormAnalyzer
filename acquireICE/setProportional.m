function setProportional(s, p)
% The function sends 'set proportional bandwidth' command to temperature
% controller at specified proportional bandwitdth p. s is serial port
% object.

% Safety feature
if ~isnumeric(p)
    disp('Proportional bandwidth must be number.');
    return
elseif ~isscalar(p)
    disp('Proportional bandwidth must be scalar.');
    return
elseif isnan(p)
    disp('Proportional bandwidth must not be NaN.');
    return
elseif p < 0
    disp('Proportional bandwidth is too low.');
    return
elseif p > 100
    disp('Proportional bandwidth is too high.');
    return
end


% Temperature is multiplied by 100
p100 = round(p * 100);

% Hex value of the above
phex = dec2hex(int32(p100));

% Append leading zeros to make it 8 digits
pzero = sprintf('%08s', phex);

% * + device number(00) + command (01) + temperature + checksum + CR
cmd = lower(['*0011', pzero, chksum(['0011', pzero]), '\n']);

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
% p = hex2dec(ret(7:9)) / 100;
% disp(['Temperature set to ', num2str(t), 'C degrees.']);

end
