function offset = offsetTemp(temperture, offsetAtT1, T1, offsetAtT2, T2)

a = (offsetAtT2 - offsetAtT1) / (T2 - T1);
b = offsetAtT1 - a * T1;
offset = a * temperture + b;

if isnan(offset)
    offset = 0;
end

end
