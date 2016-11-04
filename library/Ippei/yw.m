function yw(WOEID)

if ~exist('WOEID', 'var')
    WOEID = 4118; % Toronto = '4118';
end

% URL = ['http://weather.yahooapis.com/forecastrss?w=' num2str(WOEID) '&u=c'];
URL = ['https://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20weather.forecast%20where%20woeid=' num2str(WOEID), '%20AND%20u="c"'];

% Open connection to Yahoo weather API
ur      = java.net.URL(URL);        % Construct a URL object
oc      = ur.openConnection;
oc.setReadTimeout(1000);
oc.setConnectTimeout(1000);

try
    oc.connect();
    is      = oc.getInputStream();      % Open a connection to the URL
catch err
    prt(err);
    w = 'Connection timed out';
    
    return
end

isr     = java.io.InputStreamReader(is);
br      = java.io.BufferedReader(isr);

flgOut = 0;
while(flgOut ~= 1)
    buffer = char(readLine(br));
%     disp(buffer);
    if(strfind(buffer, '<yweather'))
        st = strfind(buffer, '<yweather:');
        ed = strfind(buffer, '/>');
        nw = numel(st);
        wt = cell(nw, 1);

        for y = 1:nw
            wt{y} = buffer(st(y):ed(y));
        end

        z = 1; flgOut2 = 1;
        while (flgOut2)
            if strfind(wt{z}, 'yweather:location')
            w.city = findKeyword('city');
            w.region = findKeyword('region');
            w.country = findKeyword('country');
            elseif strfind(wt{z}, 'yweather:wind')
            w.windChill = findKeyword('chill');
            w.windSpeed = findKeyword('speed');
            elseif strfind(wt{z}, 'yweather:atmosphere')
            w.humidity = findKeyword('humidity');
            w.pressure = findKeyword('pressure');
            dt = findKeyword('rising');
            switch dt
                case '0', w.deltaPressure = 'Steady';
                case '1', w.deltaPressure = 'Rising';
                case '2', w.deltaPressure = 'Falling';
            end
            elseif strfind(wt{z}, 'yweather:astronomy')
            w.sunrise = findKeyword('sunrise');
            w.sunset = findKeyword('sunset');
            elseif strfind(wt{z}, 'yweather:condition')
            w.weather = findKeyword('text');
            w.temperature = [findKeyword('temp'), '°C'];
            w.currentDate = findKeyword('date');
            elseif strfind(wt{z}, 'yweather:forecast')
            w.date1 = findKeyword('date');
            w.day1 = findKeyword('day');
            w.high1 = [findKeyword('high'), '°C'];
            w.low1 = [findKeyword('low'), '°C'];
            z = z + 1;
            w.date2 = findKeyword('date');
            w.day2 = findKeyword('day');
            w.high2 = [findKeyword('high'), '°C'];
            w.low2 = [findKeyword('low'), '°C'];
            z = z + 1;
            w.date3 = findKeyword('date');
            w.day3 = findKeyword('day');
            w.high3 = [findKeyword('high'), '°C'];
            w.low3 = [findKeyword('low'), '°C'];
            flgOut2 = 0;
            end
            
            z = z + 1;
        end
        flgOut = 1;
    end
end

fprintf('\n');
prt(w.currentDate);
prt('Current:', w.temperature);
prt(w.weather);
prt(['Humidity: ', w.humidity, '%']);
prt('Pressure:', w.deltaPressure);
prt('Sunrise:', w.sunrise);
prt('Sunset:', w.sunset);
r1 = 5 - length(w.day1);
r2 = 5 - length(w.day2);
fprintf(['\n', w.day1, repmat(' ',1, r1), w.day2, repmat(' ',1, r2), w.day3,'\n']);
r1 = 5 - length(w.high1);
r2 = 5 - length(w.high2);
fprintf([w.high1, repmat(' ',1, r1), w.high2, repmat(' ',1, r2), w.high3,'\n']);
r1 = 5 - length(w.low1);
r2 = 5 - length(w.low2);
fprintf([w.low1, repmat(' ',1, r1), w.low2, repmat(' ',1, r2), w.low3,'\n']);
fprintf('\n');

    function fd = findKeyword(key)
                bf = wt{z};
                dq = strfind(bf,'"');
                kw = strfind(bf, [key, '="']);
                st = dq(find(dq > kw(1), 1, 'first') + 0);
                ed = dq(find(dq > kw(1), 1, 'first') + 1);
                fd = bf(st+1:ed-1);
    end

end

