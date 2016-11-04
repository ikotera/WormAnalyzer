function [tScroll, valT, frameSkip, frameWait] = playICE...
    (handles, hFunctions, command, tScroll, valT, dimT, dimZ, frameSkip, frameWait)

[path, ~, ~] = fileparts(which(mfilename));

incrementWait = 50; % for waitFrame in ms


switch command
    case 'play'
        
        dimTP = dimT / dimZ;
        %       prt handles.jButtonPlay.isSelected
        if handles.jButtonPlay.isSelected
            pathIconPlay = [path, '\icons\pause.gif'];
            handles.jButtonPlay.setIcon(javax.swing.ImageIcon(pathIconPlay));
            
            while handles.jButtonPlay.isSelected

                [frameSkip, frameWait] = hFunctions.updateVariablesFromExternalFunction();
                valT = valT + 1 + frameSkip;
                if valT > dimTP - 1
                    valT = 1;
                end
                set(handles.sliderT, 'Value', valT * handles.sliderTStep);
                pause(eps); % Pause minimum value to flash image
                hFunctions.displayImage(valT);
                hFunctions.updateDisplayStatus();
%                 hFunctions.drawVline
            end
        else
            pathIconPlay = [path, '\icons\play.gif'];
            handles.jButtonPlay.setIcon(javax.swing.ImageIcon(pathIconPlay));
            
        end
        
    case 'faster'
        if frameWait > 0
            frameWait = frameWait - incrementWait;
            if frameWait < 0
                frameWait = 0;
            end
        else
            frameSkip = frameSkip + 1;
        end
        hFunctions.updateVariablesFromExternalFunction(frameSkip, frameWait);
        hFunctions.updateDisplayStatus();
        
        
    case 'slower'
        frameSkip = frameSkip - 1;
        if frameSkip < 0
            frameSkip = 0;
            frameWait = frameWait + incrementWait;
        end
        hFunctions.updateVariablesFromExternalFunction(frameSkip, frameWait);
        hFunctions.updateDisplayStatus();
        
end

if frameSkip > 0
    prt('Skipping', frameSkip, 'frame(s).');
elseif frameSkip == 0 && frameWait == 0
    prt('Playing at unmodified speed.');
elseif frameWait > 0
    prt('Each frame waits', frameWait, 'ms.');
end

end

