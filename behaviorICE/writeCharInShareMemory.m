function writeCharInShareMemory(SM, field, text, lenField)

intText = int16(text); % Convert to integers
intText = [intText, int16(3)]; % Append end of text code
lenText = length(intText); 
paddedInt = [intText, zeros(1, lenField-lenText, 'int16')]; % Pad it with zeros

SM.Data.(field) = paddedInt; % Copy it to the shared memory

end