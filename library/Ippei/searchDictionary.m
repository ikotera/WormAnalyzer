function pron = searchDictionary(dictCMU, dictTranscript, key)

% fid = fopen('C:\Users\shakespeare\Desktop\cmudict.0.7a.txt','r');
% cl = textscan(fid, '%s%s', 'delimiter', '|');
% fclose(fid);

% key = upper(key);

tic
% index = strcmpi(dictCMU{:,1}, key);
% word = dictCMU{:, 1}{index};
% code = dictCMU{:, 2}{index};

[code, word] = searchCell(dictCMU, key);

if isempty(code)
    pron = [];
    return;
end

cPhoneme = textscan(code, '%s');


% index = strcmpi(dictCode{:,1}, code);
% word = dictCMU{:, 1}{index};
% pron = dictCMU{:, 2}{index};

ind = 1;
while 1

    str = cPhoneme{1,1}{ind};
    strNum = regexp(str, '[0-9]', 'ONCE');
    
    if ~isempty(strNum) && strNum > 1
        cPhoneme{1,1}(ind+1:end+1, :) = cPhoneme{1,1}(ind:end, :);
        cPhoneme{1,1}{ind, :} = str(1:strNum-1);
        cPhoneme{1,1}{ind+1, :} = str(strNum);
    end
    
    [trans{ind}, word] = searchCell(dictTranscript, cPhoneme{1,1}{ind}); %#ok<AGROW>
    
    if (strcmp(trans{ind}, '^') || strcmp(trans{ind}, '`') ) && strcmp(trans{ind-1}, 'E')
        trans{ind-1} = 'V'; %#ok<AGROW>
    end
    
    if (strcmp(trans{ind}, '^') || strcmp(trans{ind}, '`') ) && strcmp(trans{ind-1}, 'i')
        trans{ind-1} = 'Y'; %#ok<AGROW>
    end

    if (strcmp(trans{ind}, '^') || strcmp(trans{ind}, '`') ) && strcmp(trans{ind-1}, 'i:')
        trans{ind-1} = 'Y:'; %#ok<AGROW>
    end
    

    if (strcmp(trans{ind}, '^') || strcmp(trans{ind}, '`') ) && numel(trans{ind-1}) > 1
        trans{ind-1}(3) = trans{ind-1}(2); %#ok<AGROW>
        trans{ind-1}(2) = trans{ind}; %#ok<AGROW>
        trans{ind} = []; %#ok<AGROW>
    end
    
    if ind >= numel(cPhoneme{1,1})
        break;
    end
    ind = ind + 1;
end

pron = cat(2, trans{:});

toc

end


function [p, w] = searchCell(dict, key)

index = strcmpi(dict{:,1}, key);
if all(index == 0)
    p = [];
    w = [];
    return;
else
    w = dict{:, 1}{index};
    p = dict{:, 2}{index};
end

end

