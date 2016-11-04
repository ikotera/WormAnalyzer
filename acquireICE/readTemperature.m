function [t] = readTemperature(s)
% The function sends 'set temperature' command to temperature controller at
% specified temperatrue t. s is serial port object.

wait = 10;

fprintf(s, '*00010000000041\n');

java.lang.Thread.sleep(wait);

ret = readSerial(s);

if strcmp(ret, '*XXXXXXXXc0^')
   % Checksum is incorrect
   t = nan;
else
    % Check for out of range values
    h = ret(7:9);
    if any(any(~((h>='0' & h<='9') | (h>='a' & h<='f'))))
        t = nan;
        return
    end
    t = hex2dec(h) / 100;
end

% Adjust temperature back to non-offset temperature
% ot = t + offsetTemp(t, o1, oAt1, o2, oAt2);
% t = ot - reverseOffsetTemp(ot, o1, oAt1, o2, oAt2);
% t = ot;
end
