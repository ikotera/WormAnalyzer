function [v] = readVoltage(s)
% The function sends 'set temperature' command to temperature controller at
% specified temperatrue t. s is serial port object.

fprintf(s, '*00020000000042\n');

ret = readSerial(s);

v = hex2dec(ret(2:9)) / 1000;


end
