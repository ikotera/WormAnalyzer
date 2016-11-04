function [t, v, o] = readOven(s)
% The function retrieves temperature, voltage, and output values from the buffer. Run queryOven
% function first to get those values to the buffer. The order of retrieve is t -> v -> o.


% Read the buffer all at once
chr = fscanf(s, '%s', 36);
chrTemp = chr(1:12);
chrVol = chr(13:24);
chrOut = chr(25:36);


% Retrieve temperature value from the buffer
% ret = readSerial(s);

if strcmp(chrTemp, '*XXXXXXXXc0^')
   % Checksum is incorrect
   t = nan;
else
   t = hex2dec(chrTemp(7:9)) / 100;
end

% Retrieve votage value from the buffer
% ret = readSerial(s);
if strcmp(chrVol, '*XXXXXXXXc0^')
   % Checksum is incorrect
   v = nan;
else
   v = hex2dec(chrVol(2:9)) / 1000;
end

% Retrieve output power value from the buffer
% ret = readSerial(s);
if strcmp(chrOut, '*XXXXXXXXc0^')
   % Checksum is incorrect
   o = nan;
elseif chrOut(2) == 0
    o = hex2dec(chrOut(2:9)); o = round(o / 683 * 100);
else
    o = hex2twoscomp2dec(chrOut(2:9)); o = round(o / 683 * 100);
end


end
