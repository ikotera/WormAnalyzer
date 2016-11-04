function updateMenuIcon(col, row, menu, command, paths, iconDefault)

if strcmp(command, 'add') % just add icon
    menu{col, row}.setIcon( javax.swing.ImageIcon( paths.(iconDefault) ) );
else % toggle icons
    if command
        menu{col, row}.setIcon( javax.swing.ImageIcon(paths.iconChecked) );
    else
        menu{col, row}.setIcon( javax.swing.ImageIcon(paths.iconUnchecked) );
    end
end

end