function temperatureModule

% addpathShakespeare;

namePort = 'COM4';

% Initialize 5R6-900
objSer = serial(namePort, 'BaudRate', 19200);
fopen(objSer);
set(objSer, 'Terminator', {'CR','CR'});
disp([namePort, ' open.']);

% Disable output
setOutput(objSer, 0);

% % Initialize DAQ
% objDAQ = daq.createSession('ni');
% objDAQ.addAnalogInputChannel('Dev1', 'ai0', 'Thermocouple');
% objDAQ.Rate = 20;
% objDAQ.IsContinuous = true;
% 
% objTC1 = objDAQ.Channels(1);
% set(objTC1)
% objTC1.ThermocoupleType = 'T';
% objTC1.Units = 'Celsius';
% 
% hL = objDAQ.addlistener('DataAvailable', @pushTempData);
% objDAQ.startBackground;

% Cleanup function
objClean = onCleanup(@()fclose(objSer));




nameFile = fullfile(tempdir, 'memShared.dat');

% Create the communications file if it is not already there.
if ~exist(nameFile, 'file')
    [f, msg] = fopen(nameFile, 'wb');
    if f ~= -1
        fwrite(f, zeros(1, 64), 'double');
        fclose(f);
    else
        error('MATLAB:neuroHeater:cannotOpenFile', ...
              'Cannot open file "%s": %s.', nameFile, msg);
    end
end
 
% Memory map the file.
memShared = memmapfile(nameFile, 'Writable', true, 'Format', 'double');

memShared.Data(:) = nan;




%% Main Loop

while true
    
    if memShared.Data(1) ~= 0
        
        adr = memShared.Data(1);
        
        switch adr
            case 21
                setTemperature(objSer, memShared.Data(adr),...
                    memShared.Data(41), memShared.Data(42),...
                    memShared.Data(43), memShared.Data(44)...
                    );
            case 22
                setOutput(objSer, memShared.Data(adr));
            case 23
                setProportional(objSer, memShared.Data(adr));
            case 24
                setIntegral(objSer, memShared.Data(adr));
            case 25
                setVoltage(objSer, memShared.Data(adr));
            case 26
                
                switch memShared.Data(adr)
                    case 1
                        setCoolHeat(objSer, 'cool');
                    case 2
                        setCoolHeat(objSer, 'heat');
                end
        end
    end
    
    memShared.Data(31) = readTemperature(objSer,...
        memShared.Data(41), memShared.Data(42),...
        memShared.Data(43), memShared.Data(44));
    memShared.Data(32) = readOutput(objSer);
    memShared.Data(33) = readVoltage(objSer);
    
    if memShared.Data(2) == 1
        
        % Disable output
        setOutput(objSer, 0);
        fclose(objSer);
        
        exit;
    end
    
    
end

% % tt = 1;
% while 1
% % % Uncomment the following for profiling    
% %     tt = tt + 1;
% %     if tt >20
% %         modeOperation = 'end';
% %     end
%     
%     switch modeOperation
%         
%         case 'start'
% 
%             % Settin initial values for temperature ramp
%             t = 1;
%             tPrev = nan;
%             duration = str2double(get(hEditDuration, 'String'));
%             tempOven = nan(duration, 2);
%             tempDaq = nan(duration, 2);
%             setTemp = nan(duration, 2);
%             
%             % Get ramp values from uicontrols
%             getRampValues();
%             
%             sendTuningValues();
%             
%             tStart = tic;
%             
%             modeOperation = 'run';
%             
%         case 'run'
%                 
%             if strcmp(modeCamera, 'prePreview') ||...
%                strcmp(modeCamera, 'preAcquisition')     
%                 preparePreview;
%             elseif strcmp(modeCamera, 'preview') ||...
%                    strcmp(modeCamera, 'acquisition')
% 
% %                 displayImages;
% 
%             end
%             
%             % Initial hold
%             if toc(tStart) < holdIni
%                 
%                 setTemperature(objSer, tempIni,...
%                     offset1, offsetAt1, offset2, offsetAt2);
%                 setTemp(t, 2) = toc(tStart);
%                 setTemp(t, 1) = tempIni;
%                 
%             % Temperature ramp
%             elseif toc(tStart) >= holdIni && setTemp(t - 1, 1) < tempFin
%                 % Get tPrev if it's for the first time
%                 if isnan(tPrev)
%                     tPrev = toc(tStart);
%                 end
%                 % Increase the temperature according to the temperature
%                 % slope and the elapsed time since last increase
%                 setTemp(t, 1) = setTemp(t - 1, 1)...
%                     + (tempSlope * (toc(tStart) - tPrev));
%                 tPrev = toc(tStart);
%                 setTemperature(objSer, setTemp(t, 1),...
%                     offset1, offsetAt1, offset2, offsetAt2);
%                 setTemp(t, 2) = toc(tStart);
%                 
%             % Final hold
%             elseif toc(tStart) >= holdIni && setTemp(t - 1, 1) >= tempFin
%                 setTemp(t, 1) = setTemp(t - 1, 1);
%                 setTemp(t, 2) = toc(tStart);
%             end
%             
%             % Get current times and temperatures
%             tempOven(t, 2) = toc(tStart);
%             tempOven(t, 1) = readTemperature(objSer,...
%                 offset1, offsetAt1, offset2, offsetAt2);
%             tempDaq(t, 2) = toc(tStart);
%             tempDaq(t, 1) = tempData;
%             %                 tempDaq(t, 1) = readDaq(objDAQ);
%             
%             % Plot three temperatures
%             hold on;
%             if ~isnan(hPO)
%                 delete(hPO);
%             end
%             hPO = plot(hAxisTemp, tempOven(:, 2), tempOven(:, 1), 'Color', 'red');
%             
%             if ~isnan(hPD)
%                 delete(hPD);
%             end
%             hPD = plot(hAxisTemp, tempDaq(:, 2), tempDaq(:, 1));
%             
%             if ~isnan(hPS)
%                 delete(hPS);
%             end
%             hPS = plot(hAxisTemp, setTemp(:, 2), setTemp(:, 1), 'Color', 'green');
%             hold off;
%             
%             % Set text strings for jLabel Java object
%             updateIndicators;
%             
%             t = t + 1;
%             
%             if t > duration
%                 
%                 toggleRamp;
%             end
%             
%             drawnow;
%             
%         case 'startIdle'
%             
%             tStart = tic;
%             
%             modeOperation = 'idle';
%             tPrevIndicators = toc(tStart);
%    
%         case 'idle'
% %             tWhole = tic;
%             if strcmp(modeCamera, 'prePreview') ||...
%                strcmp(modeCamera, 'preAcquisition')     
%                 preparePreview;
%             elseif strcmp(modeCamera, 'preview') ||...
%                    strcmp(modeCamera, 'acquisition')
% 
%                 displayImages;
% 
%             end
%             
% 
% %             if (toc(tStart) - tPrevIndicators > 0.01)
% %                 updateIndicators;
% %                 tPrevIndicators = toc(tStart);
% %             end
%             
%             drawnow;
% %             toc(tWhole)
% 
%             
%         case 'end'
% 
%             objDAQ.stop();  
%             delete(hL);
%             
%             figClose;
%             
%             delete(hFig);
%             
%             break;
%             
%     end
% end
% 
% 
% 
% 
% end

% function pushTempData(~,event)
% 
% global tempData;
% 
% tempData = mean(event.Data);
% 
% end