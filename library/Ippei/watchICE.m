function watchICE

tmr = [];
listAnalyzeMe = [];
fdr = []; err = []; log = [];

[~, hostname] = system('hostname');
hostname = strtrim(hostname);
periodPrime = getPeriod(hostname);

[pathM, ~, ~] = fileparts(mfilename('fullpath'));
handles = loadGUI([pathM, '\watchICE.fig']);
pathWatch = '\\101.101.1.209\Data\working';

initializeGUI;
startWatching;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function startWatching(~, ~)
        set(handles.textProcess, 'String', 'Stand By');
        val = get(handles.radioWatch, 'Value');
        if val
            prt([hostname, ' is watching folders (interval ', num2str(periodPrime), 's) ...']);
            initiateTimer(5, periodPrime, inf, @checkFolders);
        else
            prt('Stopped Watching.');
            if issafe('tmr')
                stop(tmr);
            end
            closeTimer;
            delete(timerfind); % To be sure
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function checkFolders(~, ~)
        
        set(handles.textMessage, 'String', 'Checking the Folder...');

        listAnalyzeMe = rdir([pathWatch, '\**\analyze_me.flg']);
        nDir = numel(listAnalyzeMe);
        
        if nDir >= 200
            warning('The working folder contains more than 200 subfolders, which is slowing down watchICE');
        end
        
        for lf = 1:numel(listAnalyzeMe)
           [fdr, ~,~] = fileparts(listAnalyzeMe(lf).name);
           processing = rdir([fdr, '\**\being_processed_by*.flg']);
           if numel(processing) > 0
           else % if it's not being processed by other stations
               putFlag('being_processed');
               words = allwords(fdr, '\');
               set( handles.textFolder1, 'String', words{end-1}(8:end) );
               set( handles.textFolder2, 'String', words(end) );
               drawnow;
               prt('Start Analyze');
               closeTimer;

               try
                   log = analyzeBatch(fdr, 1, 1, 1, 1, 1, handles);
                   putFlag('completed');
                   startWatching;
                   return
               catch err
                   set(handles.textMessage, 'String', 'Error in analyzeBatch');
                   putFlag('error');

                   prt( char(10), getReport(err) );
                   startWatching;
                   return
               end
           end
        end
        pause(1);
        set(handles.textMessage, 'String', ['Waiting (interval ', num2str(periodPrime), 's) ...']);
        
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function endWatch(~, ~)
        closeTimer;
        delete(handles.figWatchICE);
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function initializeGUI
        set(handles.radioWatch, 'Callback', @startWatching);
        set(handles.radioWatch, 'Value', 1);
        set(handles.figWatchICE, 'CloseRequestFcn', @endWatch);
        set(handles.popupFolder, 'String', pathWatch);
        set(handles.textProcess, 'String', 'Standing By');
        set(handles.textMessage, 'String', 'Initializing...');
        drawnow;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function initiateTimer(delay, period, numTasks, fun)
        tmr = timer('StartDelay', delay, 'Period', period, 'TasksToExecute', numTasks, ...
            'ExecutionMode', 'fixedRate');
        tmr.TimerFcn = fun;
        start(tmr);
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function closeTimer
        if issafe('tmr') && isvalid(tmr)
            stop(tmr);
            delete(tmr);
        end
        clear tmr
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function putFlag(flag)
        fi = fopen([fdr, '\', flag, '_by_', hostname, '.flg'], 'W');
        switch flag
            case 'completed'
                fprintf( fi, strrep( evalc('log'), '\', '\\') );
                if isfield(log, 'warning')
                    fprintf( fi, strrep( log.warning, '\', '\\') );
                end
            case 'error'
                er = getReport(err, 'extended', 'hyperlinks', 'off');
                fprintf( fi, strrep( er, '\', '\\') );
        end
        fclose(fi);
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


end % end of watchICE




