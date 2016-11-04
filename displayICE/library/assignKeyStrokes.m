function assignKeyStrokes(jMenu, menu, mode)

[parents, children, keys] = getKeys(menu, mode);

cellfun(@(x, y, z) assignKey(jMenu, x, y, z), parents, children, keys ,'UniformOutput', false);

end

function assignKey(jM, parent, child, key)

jM{child, parent}.setAccelerator( javax.swing.KeyStroke.getKeyStroke(key) );

end

function [p, c , k] = getKeys(menu, mode)
switch mode
    case 'play'
        switch menu
            case 'main'
                % p, c, 'key'
                cl = {...
                    1, 4,  'S';...  % Save labels
                    1, 8,  'Q';...  % Quit
                    2, 1,  'T';...  % Time-series
                    2, 9,  'O';...  % ROI
                    2, 11, 'I';...  % Measure
                    4, 1,  'A';...  % Autoscale
                    4, 3,  'W';...  % Flip vertical
                    4, 4,  'D';...  % Flip horizontal
                    4, 6,  'C';...  % Show regions
                    4, 10, 'L';...  % Toggle Overlays
                    5, 3,  'Z';...  % RGB
                    5, 4,  'X';...  % Max projection
                    6, 3,  'R';...  % Rename neuron
                    7, 1,  'E';...  % Toggles Pointer scroll mode
                    7, 2,  'B';...  % Label Behaviors
                    7, 3,  'V';...  % Add Worm
                    7, 5,  'G';...  % Show Behaviors
                    7, 6,  'F';...  % Add Behaviors
                    7, 7,  'H';...  % Mark X
                    7, 8,  'J';...  % Demark X
                    7, 9,  'UP';... % Previous Worm
                    7, 10, 'DOWN'...% Next Worm
                    };
            case 'sub'
                cl = {...
                    1, 1,  'K';...  % Image mode disk
                    1, 2,  'M'...   % Image mode RAM
                    };
        end
    case 'behavior'
        switch menu
            case 'main'
                % p, c, 'key'
                cl = {...
                    1, 4,  '';...  % Save labels
                    1, 8,  '';...  % Quit
                    2, 1,  '';...  % Time-series
                    4, 1,  '';...  % Autoscale
                    4, 3,  '';...  % Flip vertical
                    4, 4,  '';...  % Flip horizontal
                    4, 10, '';...  % Toggle Overlays
                    6, 3,  '';...  % Rename neuron
                    7, 1,  'E';... % Toggles Pointer scroll mode
                    7, 2,  'R';... % Label Behaviors
                    7, 3,  '';...  % Add Worm
                    7, 5,  '';...  % Show Behaviors
                    7, 6,  '';...  % Add Behaviors
                    7, 7,  '';...  % Mark X
                    7, 8,  '';...  % Demark X
                    7, 9,  '';...  % Previous Worm
                    7, 10, ''...   % Next Worm
                    };
            case 'sub'
                cl = {...
                    1, 1,  '';...  % Image mode disk
                    1, 2,  ''...   % Image mode RAM
                    };
        end
end



p = cl(:, 1);
c = cl(:, 2);
k = cl(:, 3);

end
