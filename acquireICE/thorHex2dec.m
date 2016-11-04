function dec = thorHex2dec(thorHex, byteIni, byteEnd)

% Converts hex characters acquired from Thorlab stage via serial port to numeric value.

byteIni = byteIni + 1;
byteEnd = byteEnd + 1;

numElem = numel(thorHex(byteIni:byteEnd, :));

dec = hex2dec(reshape(flipud(thorHex(byteIni:byteEnd, :))', 1, numElem));

end