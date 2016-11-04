function processOven

% dbstop in processOven 43;

% commandWindowOnly;

clc;

waitOven = 0.6;

tableOven = table(false(6,1), zeros(6,1),...
    'RowNames', {'sTemperature'; 'sVoltage'; 'sOutput'; 'sProp'; 'sInteg'; 'sCoolheat'});
tableOven.Properties.VariableNames = {'flag', 'previous'};
tableOven{'sTemperature', 'previous'} = nan;
tableOven{'sVoltage', 'previous'} = nan;
tableOven{'sOutput', 'previous'} = nan;
tableOven{'sProp', 'previous'} = nan;
tableOven{'sInteg', 'previous'} = nan;
tableOven{'sCoolheat', 'previous'} = nan;

namePort = 'COM2';

% Initialize 5R6-900
objOven = serial(namePort, 'BaudRate', 19200);
fopen(objOven);
set(objOven, 'Terminator', {'CR','CR'});
disp([namePort, ' open.']);

% Disable output
setOutput(objOven, 0);
pause(waitOven);
fscanf(objOven, '%s', 12);
pause(waitOven);

% Cleanup function
objClean = onCleanup( @()cleanup() );

% Create a template file for memory mapping
nameFile = fullfile(tempdir, 'memSerial.dat');
SM = memmapfile(nameFile, 'Writable', true, 'Format', 'double');
SM.Data(2) = 1; % I'm ready
SM.Data(4) = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

while true
    
    if SM.Data(1) == 1 % master has requested
        
        writeOven;
        pause(waitOven);
        
        readOven;
        prt( 'rT:' ,SM.Data(31), 'rV:', SM.Data(32), 'rO:', SM.Data(33), 'sT:', SM.Data(21) );
        pause(waitOven);

    end
    
    if SM.Data(4) == 1
        selfDestruct;
    end
    
    pause(waitOven);
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function readOven
        
        tableOven{:, 1} = false;
        
        ba = objOven.BytesAvailable;
%         prt('Bytes available:', ba);
        
        results = fscanf(objOven, '%s', ba); % Three results previously requested
        results = results(end - 35:end);

        for ind = 1:3
            
            hex = results(1, 12 * (ind - 1) + 2 : 12  * ind - 3);
            
            % Check for errors in returned hexes
            if strcmp(hex, '*XXXXXXXXc0^') % Checksum is errornous
                prt( 'Checksum error:', 'index =', ind, 'hex =', hex);
                return
            elseif any( any( ~( (hex >= '0' & hex <= '9') |...
                    (hex >= 'a' & hex <= 'f') ) ) ) % Check for out of range values
                prt( 'Out of range value:', 'index =', ind, 'hex =', hex);
                return
            end
            
            if ind == 1 % temperature
                SM.Data(31) = hex2dec(hex) / 100;
            elseif ind == 2 % voltage
                SM.Data(32) = hex2dec(hex) / 1000;
            elseif ind == 3 % output
                if strcmp(hex(2), '0');
                    output = hex2dec(hex);
                else
                    output = hex2twoscomp2dec(hex);
                end
                SM.Data(33) = round(output / 683 * 100);
            end
        end
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function writeOven
        
        str = [];
        
        % Add commands to request if the current variables are changed from previous ones
        if checkSafety(SM.Data, 21) && tableOven{'sTemperature', 'previous'} ~= SM.Data(21) %#ok<*BDSCA>
            tableOven{'sTemperature', 'previous'} = SM.Data(21);
            tableOven{'sTemperature', 'flag'} = true;
            tmp = round(SM.Data(21) * 100); % Temperature is multiplied by 100
            str = convertOvenCommand(tmp, '10');
        else
            str = [str, ''];
        end
        
        if checkSafety(SM.Data, 22) && tableOven{'sVoltage', 'previous'} ~= SM.Data(22)
            tableOven{'sVoltage', 'previous'} = SM.Data(22);
            tableOven{'sVoltage', 'flag'} = true;
            vol = SM.Data(22) * 1000; % voltage is multiplied by 1000
            str = [str, convertOvenCommand(vol, '16')];
        else
            str = [str, ''];
        end
        
        if checkSafety(SM.Data, 23) && tableOven{'sOutput', 'previous'} ~= SM.Data(23)
            tableOven{'sOutput', 'previous'} = SM.Data(23);
            tableOven{'sOutput', 'flag'} = true;
            str = [str, convertOvenCommand(SM.Data(23), '1d')];
        else
            str = [str, ''];
        end
        
        if checkSafety(SM.Data, 24) && tableOven{'sProp', 'previous'} ~= SM.Data(24)
            tableOven{'sProp', 'previous'} = SM.Data(24);
            tableOven{'sProp', 'flag'} = true;
            prop = round(SM.Data(24) * 100);
            str = [str, convertOvenCommand(prop, '11')];
        else
            str = [str, ''];
        end
        
        if checkSafety(SM.Data, 25) && tableOven{'sInteg', 'previous'} ~= SM.Data(25)
            tableOven{'sInteg', 'previous'} = SM.Data(25);
            tableOven{'sInteg', 'flag'} = true;
            integ = round(SM.Data(25) * 100);
            str = [str, convertOvenCommand(integ, '12')];
        end
        
        if checkSafety(SM.Data, 26)
            tableOven{'sCoolheat', 'previous'} = SM.Data(26); % 2 -> 1, 1 -> 0
            tableOven{'sCoolheat', 'flag'} = true;
            str = [str, convertOvenCommand(SM.Data(26) - 1, '18')];
        else
            str = [str, ''];
        end
        
        % Adding request for current status
        str = [str, '*00010000000041\n*00020000000042\n*00040000000044\n'];
        
        if ~isempty(str)
            % Send commands put together above
            fprintf(objOven, '%s',str);
        end
        
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function isSafe = checkSafety(data, index)
        
        % Safety check for Oven commands
        if ~isnumeric( data(index) )
            prt('Sending data must be number. Index:', index);
            isSafe = false;
            return
        elseif ~isscalar( data(index) )
            prt('Sending data must be scalar. Index:', index);
            isSafe = false;
            return
        elseif isnan( data(index) )
            prt('Sending data must not be NaN. Index:', index);
            isSafe = false;
            return
        elseif index == 21 && data(index) < 4
            prt('Temperature is too low.');
            isSafe = false;
            return
        elseif index == 21 && data(index) > 70
            prt('Temperature is too high.');
            isSafe = false;
            return
        elseif index == 22 && data(index) < 2
            prt('Voltage is too low.');
            isSafe = false;
            return
        elseif index == 22 && data(index) > 10
            prt('Voltage is too high.');
            isSafe = false;
            return
        elseif index == 23 && ~(data(index) == 0 || data(index) == 1)
            prt('Output must be 1 or 0.');
            isSafe = false;
            return
        elseif index == 24 && data(index) < 0
            prt('Proportional bandwidth is too low.');
            isSafe = false;
            return
        elseif index == 24 && data(index) > 100
            prt('Proportional bandwidth is too high.');
            isSafe = false;
            return
        elseif index == 25 && data(index) < 0
            prt('Integral gain is too low.');
            isSafe = false;
            return
        elseif index == 25 && data(index) > 10
            prt('Integral gain is too high.');
            isSafe = false;
            return
        elseif index == 26 && ~(data(index) == 1 || data(index) == 2)
            prt('Coolheat must be 1 (cool) or 2 (heat).');
            isSafe = false;
            return
        else
            isSafe = true;
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function str = convertOvenCommand(value, command)

        % Hex value from Oven
        hex = dec2hex(int32(value));
        
        % Append leading zeros to make it 8 digits
        hexzeros = sprintf('%08s', hex);
        
        % * + device number(00) + command (01) + temperature + checksum + CR
        str = lower(['*00', command, hexzeros, chksum(['00', command, hexzeros]), '\n']);

    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function selfDestruct
        
        pause(waitOven);
        SM.Data(4) = 0;
        % If self-destruct sequence is initiated by the master
        clear SM;
        % Disable output for safety reasons
        setOutput(objOven, 0);
        pause(waitOven);
        fclose(objOven);
        delete(objOven);
        clear objClean objOven tableOven
        exit;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function cleanup(~, ~)
    if ~isempty(instrfind)
        fclose(instrfind);
        delete(instrfind);
        prt('Cleanup done');
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%







