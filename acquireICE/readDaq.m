function t = readDaq(s)

data = s.inputSingleScan();
t = mean(data);

end