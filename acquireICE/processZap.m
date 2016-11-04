function processZap

% dbstop in processZap 49;

clc;
overhead = 7;

% Allocate shared memory
nameFile = fullfile(tempdir, 'memZap.dat');
smZap = memmapfile(nameFile, 'Writable', true,...
    'Format', 'double');

% memSharedZap.Data(1) -- fire if true
% memSharedZap.Data(2) -- output power in mW
% memSharedZap.Data(3) -- zap duration in ms
% memSharedZap.Data(4) -- flag for self-destruct sequence, destroy this instance
% memSharedZap.Data(5) -- Pulse mode if true otherwise continuous mode
% memSharedZap.Data(6) -- flag for interuption of long pulse 

% Initialize Daq for laser control
objDaqAOLaser = daq.createSession('ni');
objDaqAOLaser.addAnalogOutputChannel('cDAQ1Mod3', 'ao1', 'Voltage');
objDaqAOLaser.Rate = 10000;


% Run the laser to get rid of initial overhead
% outputAnalogLaser(objDaqAOLaser, 1);
% java.lang.Thread.sleep(10);
outputAnalogLaser(objDaqAOLaser, 0);

smZap.Data(1);
smZap.Data(2);
smZap.Data(3);
smZap.Data(4) = 0;
prt('Whenever you''re ready...');

%% Main Loop

fire = 0;
    
while true
    
    if smZap.Data(1) % Time to fire
        if smZap.Data(5) % Pulse mode
            
            disp('Fire!');
            tic;
            % Output laser according to the value in shared memory(2)
            outputAnalogLaser(objDaqAOLaser, smZap.Data(2));
            % Wait according to the value in shared memory(3)
%             prt(smZap.Data(1), ' ', smZap.Data(2), ' ', smZap.Data(3), ' ', smZap.Data(4), ' ', smZap.Data(5), ' ', smZap.Data(6));
            timeWait = smZap.Data(3);
            
            if timeWait < 2000 % Short and precise wait
                if fire == 0
                    java.lang.Thread.sleep(timeWait - overhead - 2);
                else
                    java.lang.Thread.sleep(timeWait - overhead);
                end
            else % Long and interuptable wait
                et = tic;
                while toc(et) < (timeWait) / 1000
                    java.lang.Thread.sleep(100);
                    if smZap.Data(6)
                        break;
                    end
                end
            end
            
            outputAnalogLaser(objDaqAOLaser, 0);
            toc;
            disp('Done.');
            fire = fire + 1;
            
            % Put the flag back to 0
            smZap.Data(1) = 0;
            
        else % Continuous mode
            % Output laser according to the value in shared memory(2)
            outputAnalogLaser(objDaqAOLaser, smZap.Data(2));
            prt(smZap.Data(2));
        end
        
    end
    

    
    % If self-destruct sequence is initiated by the master
    if smZap.Data(4) == 1
        
        smZap.Data(4) = 0;
        outputAnalogLaser(objDaqAOLaser, 0);
        clear memSharedZap;
        % Disable output
        prt(fire);pause(2);
        delete(objDaqAOLaser);

        exit;
    end
    
    % The wait here should be >10 ms to avoid fluctuation in acquireICE instance
%     java.lang.Thread.sleep(10);
%     prt(smZap.Data(1), ' ', smZap.Data(2), ' ', smZap.Data(3), ' ', smZap.Data(4), ' ', smZap.Data(5), ' ', smZap.Data(6));
    pause(0.01);
end


