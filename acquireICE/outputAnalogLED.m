function outputAnalogLED(s, V)

% Safety features
if ~isnumeric(V)
    disp('Voltage must be number.');
    return
elseif ~isscalar(V)
    disp('Voltage must be scalar.');
    return
elseif isnan(V)
    disp('Voltage must not be NaN.');
    return
elseif V < 0
    disp('Voltage is too low.');
    return
elseif V > 5
    disp('Voltage is too high.');
    return
end

s.outputSingleScan(V);

end

