function rOffset = reverseOffsetTemp(temperture, offsetAtT1, T1, offsetAtT2, T2)

a = (offsetAtT2 - offsetAtT1) / (T2 - T1);
b = offsetAtT1 - a * T1;
rOffset = (temperture - b) /(a);

if isnan(rOffset)
    rOffset = 0;
end

end
