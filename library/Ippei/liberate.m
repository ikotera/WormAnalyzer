function bool = liberate(obj)

str = inputname(1);

if issafe(str)
    try
        delete(obj);
        bool = true;
    catch
        bool = false;
    end
else
    bool = false;
end