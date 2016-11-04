function [output] = readOutput(s)
% The function reads output value from temperature controller. Maximum
% value is 683 and minimum is -638 in hex. Negative numbers are expressed
% in two's complement in hex. s is serial port object.

fprintf(s, '*00040000000044\n');

ret = readSerial(s);

if ret(2) == 0
    output = hex2dec(ret(2:9));
else
    output = hex2twoscomp2dec(ret(2:9));
end

output = round(output / 683 * 100);

end
