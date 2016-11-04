function queryOven(s)
% The function sends query commands to Oven Industries' 5R6-900. It will take ~30ms before the box
% sends return values to the buffer. Use 'readOven' function to retrieve data from the buffer ~30ms
% after this function.

wait = 0;
java.lang.Thread.sleep(wait);
% Query temperature, voltage, and output all at once
fprintf(s, '*00010000000041\n*00020000000042\n*00040000000044\n');
java.lang.Thread.sleep(wait);

end
