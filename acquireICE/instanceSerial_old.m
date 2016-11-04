function instanceSerial_old

threshold = 0.01;

% dbstop in instanceSerial 26;

namePort = 'COM4';

% Initialize 5R6-900
objSer = serial(namePort, 'BaudRate', 19200);
fopen(objSer);
set(objSer, 'Terminator', {'CR','CR'});
disp([namePort, ' open.']);

% Disable output
setOutput(objSer, 0);

% Cleanup function
objClean = onCleanup(@()fclose(objSer));

% Create a template file for memory mapping
nameFile = fullfile(tempdir, 'memSharedSerial.dat');
memSharedSerial = memmapfile(nameFile, 'Writable', true,...
   'Format', 'double');

%% Main Loop
% for o = 1:50
% fprintf(objSer, '*00020000000042\n');end
tLoop = tic;

while true
   
   if toc(tLoop) > threshold
      toc(tLoop)
      % Receive data from the master if it's ready
      if memSharedSerial.Data(1) ~= 0
         % Which control parameter to receive
         adr = memSharedSerial.Data(1);
         
         switch adr
            % For set temperature
            case 21
               setTemperature(objSer, memSharedSerial.Data(adr),...
                  memSharedSerial.Data(41), memSharedSerial.Data(42),...
                  memSharedSerial.Data(43), memSharedSerial.Data(44)...
                  );
               % Output
            case 22
               setOutput(objSer, memSharedSerial.Data(adr));
               % Proportional
            case 23
               setProportional(objSer, memSharedSerial.Data(adr));
               % Integral
            case 24
               setIntegral(objSer, memSharedSerial.Data(adr));
               % Voltage
            case 25
               setVoltage(objSer, memSharedSerial.Data(adr));
               % CoolHeat
            case 26
               switch memSharedSerial.Data(adr)
                  case 1
                     setCoolHeat(objSer, 'cool');
                  case 2
                     setCoolHeat(objSer, 'heat');
               end
         end
         
         % Put the flag back to 0
         memSharedSerial.Data(1) = 0;
      end
      
%       Read Oven temperature and send it back to master
      memSharedSerial.Data(31) = readTemperature(objSer,...
         memSharedSerial.Data(41), memSharedSerial.Data(42),...
         memSharedSerial.Data(43), memSharedSerial.Data(44));
      % Read Output and send it
      memSharedSerial.Data(32) = readOutput(objSer);
%       Read voltage and send it
      memSharedSerial.Data(33) = readVoltage(objSer);
      
%       fprintf(objSer, '*00020000000042\n');
%       ret = fscanf(objSer, '%s', 1);
%       memSharedSerial.Data(33) = hex2dec(ret(2:9)) / 1000;
%       memSharedSerial.Data(31) = 15;
%       memSharedSerial.Data(32) = 50;
%        memSharedSerial.Data(33) = 7;
       
       
      % If self-destruct sequence is initiated by the master
      if memSharedSerial.Data(2) == 1
         clear memSharedSerial;
         % Disable output
         setOutput(objSer, 0);
         fclose(objSer);
         exit;
      end
      
      tLoop = tic;
   end
end


