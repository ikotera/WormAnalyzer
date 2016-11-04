    function checkForDuplicatedFlags(namePath)
        flags = rdir([namePath, '\**\being_processed_by*.flg']);
        if numel(flags) > 1
            [~, hostname] = system('hostname');
            hostname = strtrim(hostname);
            for fl = 1:numel(flags)
                L = max( strfind(flags(fl).name, '_') ) + 1;
                R = max( strfind(flags(fl).name, '.') ) - 1;
                nameFlag{fl} = flags(fl).name;
                metricFlag(fl) = getPeriod( nameFlag{fl}(L:R) ); %#ok<*AGROW>
                myFlag(fl) = strcmp(nameFlag{fl}(L:R), hostname);
            end
            if metricFlag(myFlag) ~= min(metricFlag) % If my metric is the smallest one
                delete( nameFlag{myFlag} );
                error(['Duplicated flag detected. Deleting *', nameFlag{myFlag}(L:R), '.flg']);
            end
                
        end
    end

