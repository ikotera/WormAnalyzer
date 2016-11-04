function cs = chksum(ch)
% Calculates check sum to add at the end of each serial command for Oven
% Industries' temperature controller.

numCh = length(ch);

sum = 0;

for i = 1:numCh
    sum = sum + double(lower(ch(i)));
end

cs = lower(dec2hex(mod(sum, 256)));