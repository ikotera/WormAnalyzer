function sum = sumAscii(ch)

numCh = length(ch);

sum = 0;

for i = 1:numCh
    sum = sum + double(ch(i));
end