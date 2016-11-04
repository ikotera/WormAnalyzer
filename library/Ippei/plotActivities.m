function plotActivities(nameFile)
% dbstop in plotActivities 6;
% nameFile = 'C:\Users\shakespeare\Desktop\CSVFile.csv';

%% Initialize variables.
% nameFile = 'C:\Users\shakespeare\Desktop\CSVFile.csv';
delimiter = ',';
rowStart = 2;       % Start row in the CSV file
intStartTime = 17;  % Days start at this hour
nXL = 24;           % Number of x labels
iYL = 5;            % Intervals between y labels
[numStartTime, ~] = splitNumDate( datenum([num2str(intStartTime), ':00']) );

%% Format string for each line of text:
formatSpec = '%s%s%s%s%s%s%s%s%s%s%s%s%[^\n\r]';

%% Open the text file.
idFile = fopen(nameFile,'r');

%% Read columns of data according to format string.
dataArray = textscan(idFile, formatSpec, 'Delimiter', delimiter, 'MultipleDelimsAsOne', true, 'HeaderLines' ,rowStart-1, 'ReturnOnError', false);
dataArray = cellfun(@(x) regexprep(x, '\sE[DS]T|"|''', ''), dataArray, 'UniformOutput', false);  % Remove  EST,  EDT, ", and '

sn = datenum(strcat(dataArray{3}, {'-'}, dataArray{4}, {'-'}, dataArray{5}), 'mmm dd-yyyy-HH:MM:SS PM'); % Create serial date num
en = datenum(strcat(dataArray{6}, {'-'}, dataArray{7}, {'-'}, dataArray{8}), 'mmm dd-yyyy-HH:MM:SS PM'); % Create serial date num

fclose(idFile);

%% Create output variable
ta = table(dataArray{1:end-1}, sn, en, 'VariableNames', {...
    'TaskName',...
    'TaskDescription',...
    'StartDate',...
    'StartYear',...
    'StartTime',...
    'EndDate',...
    'EndYear',...
    'EndTime',...
    'Duration',...
    'DurationHours',...
    'Note',...
    'Category',...
    'StartNum',...
    'EndNum'});

%% Extract events for plotting
figure;hold on
dayMin = inf; dayMax = 0;

for ind = 1:height(ta)

    switch ta.TaskName{ind}
        case 'Sleeping'
            getAndPlotEvents;
            set(hl, 'Color', [0.6 0.6 0.9]);
        case 'Coffee'
            getAndPlotEvents;
            set(hl, 'Color', [0.5 0.5 0.5]);
        case 'Gym'
            getAndPlotEvents;
            set(hl, 'Color', [.5 .8 0]);            
        otherwise
            switch ta.Category{ind}
                case 'Waste'
                    getAndPlotEvents;
                    set(hl, 'Color', [0.9 0.6 0.6]);
                case 'Productive'
                    getAndPlotEvents;
                    set(hl, 'Color', [0.5 1 0.5]);
                case 'Mandatory'
                    getAndPlotEvents;
                    set(hl, 'Color', [0.93 0.8 0.4]);                    
            end
            
    end
    if dayMin > dayS, dayMin = dayS; end
    if dayMax < dayE, dayMax = dayE; end
end

for ind = 1:height(ta)
    switch ta.TaskName{ind}
        case 'Melatonin'
            getAndPlotEvents;
            set(hl, 'Color', [0.3 0.3 1], 'Marker', 'x');
%             uistack(hl,'top');
    end
end

xl = datestr(dayMin:iYL:dayMax, 'mm/dd');
yl = datestr( circshift(1:nXL, -intStartTime+1, 2) / nXL, 'HH:MM' );
datetick('x', 'mm/dd');
set(gca, 'YDir','reverse');
set(gca, 'YTick', 0:1/nXL:1);
set(gca, 'YTickLabel',{yl});
set(gca, 'XTick', dayMin:iYL:dayMax);
set(gca, 'XTickLabel',{xl});
set(gca, 'XTickLabelRotation', 45);
xlim([dayMin-1 dayMax+1]);
new = copyobj(gca, gcf);
set(new, 'YAxisLocation', 'right');
hold off

    function getAndPlotEvents
        numS = ta.StartNum(ind) - numStartTime;
        numE = ta.EndNum(ind) - numStartTime;
        
        [timeS, dayS] = splitNumDate(numS);
        [timeE, dayE] = splitNumDate(numE);
        
        if dayS == dayE
            hl = line([dayS, dayS], [timeS, timeE], 'LineWidth', 3);
        else
            hl(1) = line([dayS, dayS], [timeS, 1], 'LineWidth', 3);
            hl(2) = line([dayE, dayE], [0, timeE], 'LineWidth', 3);
        end
    end

end

function [numTime, numDay] = splitNumDate(numDate)
        numDay = floor(numDate);
        numTime = numDate - numDay;
end












