    function updateElapsedTime(handles, tElapsed)
        
        set(handles.textElapsedTime,...
            'String', datestr(datenum(0,0,0,0,0,toc(tElapsed)),'HH:MM:SS'));
%         prt(datestr(datenum(0,0,0,0,0,toc(tElapsed)),'HH:MM:SS'));
%         drawnow;
    end