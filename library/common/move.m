function move(nameVar)

if ischar(nameVar)
    try
    assignin('base', nameVar, evalin('caller', nameVar));
    prt('''\ns', nameVar, '\ns'' saved to base (caller method).');
    catch err
        prt(err);
    end
else
    assignin('base', inputname(1), nameVar);
    prt('''\ns', inputname(1), '\ns'' saved to base (inputname method).');
end


end