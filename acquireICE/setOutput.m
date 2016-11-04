function setOutput(s, w)
% The function sends 'output enable' command to temperature controller. s
% is serial port object.

% Safety feature
if ~isnumeric(w)
    disp('Switch must be number.');
    return
elseif ~isscalar(w)
    disp('Switch must be scalar.');
    return
elseif isnan(w)
    disp('Switch must not be NaN.');
    return
elseif ~(w == 0 || w == 1)
    disp('Switch must be 1 or 0.');
    return
end

% Hex value of the above
thex = dec2hex(int32(w));

% Append leading zeros to make it 8 digits
tzero = sprintf('%08s', thex);

% * + device number(00) + command (01) + Switch + checksum + CR
cmd = lower(['*001d', tzero, chksum(['001d', tzero]), '\n']);

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
% rs = readSerial(s);

% if strcmp(rs, '*0000000080^')
%     ret = 0;
% elseif strcmp(rs, '*0000000181^')
%     ret = 1;
% else
%     ret = nan;
% end

end
