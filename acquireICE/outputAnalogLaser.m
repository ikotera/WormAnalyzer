function outputAnalogLaser(s, mv)

% Safety features
if ~isnumeric(mv)
    disp('Voltage must be number.');
    return
elseif ~isscalar(mv)
    disp('Voltage must be scalar.');
    return
elseif isnan(mv)
    disp('Voltage must not be NaN.');
    return
elseif mv < 0
    disp('Voltage is too low.');
    return
elseif mv > 600
    disp('Voltage is too high.');
    return
end

v = mv / 100;

s.outputSingleScan(v);

end

