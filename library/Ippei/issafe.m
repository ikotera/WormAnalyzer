function [bool, detail] = issafe(str)

dot = strfind(str, '.');

if ~isempty(dot) % variable
    
    ex =  evalin('caller', ['isfield(', str(1:dot-1), ', ''' str(dot+1:end), ''');'] );
    detail = 'field';
    
else % structure field
    ex = evalin('caller', ['exist(''', str, ''', ''var'');'] );
    detail = 'variable';
end

if ex
    obj = evalin('caller', ['isobject(', str, ');'] );
    hdl = evalin('caller', ['ishandle(', str, ');'] );
    
    if obj
        bool = true;
        detail = [detail, ':object'];
    elseif hdl
        bool = true;
        detail = [detail, ':handle'];
    else
        bool = false;
        detail = [detail, ':unknown'];
    end
    
else
    bool = false;
    detail = 'non-existent';
end

end