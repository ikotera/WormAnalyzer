function type = checkPathType(path)

% This function returns the type of drive that the input path belongs. It
% requires .NET framework installed. Posible outcomes are: Fixed, UNC,
% Network, CDRom, Removable, Non-rooted, and Invalid.

if ~System.IO.Path.IsPathRooted(path) % If the path is NOT rooted, i.e., '\\', 'C:\', or '\'.
    type = 'Non-rooted';
else
    if strcmp(path(1:2), '\\') % If it's UNC
        type = 'UNC';
        return;      
    elseif strcmp(path(1), '\') % If it's '\', which is invalid
        type = 'Invalid';
        return;
    end
    % Check if it's Network or Fixed drive
    type = System.IO.DriveInfo(System.IO.Path.GetPathRoot(path)).DriveType.ToString;
end

end