function outputAnalog(s, um)

v = um / 10;

% Safety features
if ~isnumeric(v)
    disp('Voltage must be number.');
    return
elseif ~isscalar(v)
    disp('Voltage must be scalar.');
    return
elseif isnan(v)
    disp('Voltage must not be NaN.');
    return
elseif v < -2
    disp('Voltage is too low.');
    return
elseif v > 10
    disp('Voltage is too high.');
    return
end


s.outputSingleScan(v);

end

