function [t, v, o] = readOvenInverse(s)
% The function retrieves temperature, voltage, and outpu values from the buffer. Run queryOven
% function first to get those values to the buffer. The order of retrieve is o -> v -> t.


% Retrieve output power value from the buffer
ret = readSerial(s);
if strcmp(ret, '*XXXXXXXXc0^')
   % Checksum is incorrect
   o = nan;
elseif ret(2) == 0
    o = hex2dec(ret(2:9)); o = round(o / 683 * 100);
else
    o = hex2twoscomp2dec(ret(2:9)); o = round(o / 683 * 100);
end

% Retrieve votage value from the buffer
ret = readSerial(s);
if strcmp(ret, '*XXXXXXXXc0^')
   % Checksum is incorrect
   v = nan;
else
   v = hex2dec(ret(2:9)) / 1000;
end

% Retrieve temperature value from the buffer
ret = readSerial(s);

if strcmp(ret, '*XXXXXXXXc0^')
   % Checksum is incorrect
   t = nan;
else
   t = hex2dec(ret(7:9)) / 100;
end

end
