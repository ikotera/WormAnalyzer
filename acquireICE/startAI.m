% This script is required to reuse MMCore java object from one MATLAB
% session to other.

mode = 'imaging';

switch mode
    case {'imaging', 'imagingNoTemp'}
        % Check to see if there is mmc java object from previous session
        ismmc = evalin('base', 'exist(''mmc'')');
        if ismmc
            isjav = evalin('base', 'isjava(mmc)');
        end

        if ismmc && isjav % If mmc is java object then load it from base workspace
            mmc = evalin('base', 'mmc');
        else % Otherwise create one by calling MMCore
            % Specify MM jar file location
            javaaddpath({...
                'C:\Micro-Manager-1.4\ij.jar',...
                'C:\Micro-Manager-1.4\plugins\Micro-Manager\MMAcqEngine.jar',...
                'C:\Micro-Manager-1.4\plugins\Micro-Manager\MMCoreJ.jar',...
                'C:\Micro-Manager-1.4\plugins\Micro-Manager\MMJ_.jar',...
                'C:\Micro-Manager-1.4\plugins\Micro-Manager\clojure.jar',...
                'C:\Micro-Manager-1.4\plugins\Micro-Manager\bsh-2.0b4.jar',...
                'C:\Micro-Manager-1.4\plugins\Micro-Manager\swingx-0.9.5.jar',...
                'C:\Micro-Manager-1.4\plugins\Micro-Manager\swing-layout-1.0.4.jar',...
                'C:\Micro-Manager-1.4\plugins\Micro-Manager\commons-math-2.0.jar'});
            import mmcorej.*;
            % Create MMC object
            mmc = CMMCore();
            % Save the object in base memory for later reuse
            assignin('base', 'mmc', mmc);
            mmc.enableDebugLog(0);
            mmc.enableStderrLog(0);
            % Read the MM config file
            mmc.loadSystemConfiguration('C:\Micro-Manager-1.4\MMConfig_Nikon_Andor_GR_LED.cfg');
        end
        
    case 'noimaging'
end

acquireICE(mode);

