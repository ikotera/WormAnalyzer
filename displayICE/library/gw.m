function gw(WOEID)

if ~exist('WOEID', 'var')
    WOEID = 4118; % Toronto = '4118';
end

% URL = ['http://weather.yahooapis.com/forecastrss?w=' num2str(WOEID) '&u=c'];
URL = ['https://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20weather.forecast%20where%20woeid%3D' num2str(WOEID)];

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
    current = 'Connection timed out';
    
    return
end

% is      = openStream(url);
isr     = java.io.InputStreamReader(is);
br      = java.io.BufferedReader(isr);

current.temperature = [];
current.humidity = [];
current.weather = [];
% current.forecastWeather = [];
% current.forecastHigh = [];
% current.forecastLow = [];
current.pressure = [];
current.deltaPressure = [];
current.windSpeed = [];
current.windChill = [];
current.sunrise = [];
current.sunset = [];

% forecast.weather = [];
% forecast.high = [];
% forecast.low = [];
% forecast.day = [];

% Look for the following tags and acquire the text info
flgOut = 0; ind = 1;
while(flgOut ~= 1)
    buffer = char(readLine(br));
    if(strfind(buffer, 'yweather:location'))
        anchors                 = strfind(buffer,'"');
        current.city            = buffer(anchors(1) + 1:anchors(2) - 1);
        current.region          = buffer(anchors(3) + 1:anchors(4) - 1);
        current.country         = buffer(anchors(5) + 1:anchors(6) - 1);
    elseif(strfind(buffer, 'yweather:wind'))
        anchors                 = strfind(buffer,'"');
        current.windChill       = [buffer(anchors(1) + 1:anchors(2) - 1), char(176), 'C'];
        current.windSpeed       = [buffer(anchors(5) + 1:anchors(6) - 1), ' km/h'];
    elseif(strfind(buffer, 'yweather:atmosphere'))
        anchors                 = strfind(buffer,'"');
        current.humidity        = [buffer(anchors(1) + 1:anchors(2) - 1), '%'];
        current.pressure        = [buffer(anchors(5) + 1:anchors(6) - 1), ' mb'];
        delta                   = buffer(anchors(7) + 1:anchors(8) - 1);
        switch delta
            case '0', current.deltaPressure = 'steady';
            case '1', current.deltaPressure = 'rising';
            case '2', current.deltaPressure = 'falling';
        end
    elseif(strfind(buffer, 'yweather:astronomy'))
        anchors                 = strfind(buffer,'"');
        current.sunrise         = buffer(anchors(1) + 1:anchors(2) - 1);
        current.sunset          = buffer(anchors(3) + 1:anchors(4) - 1);
    elseif(strfind(buffer, 'yweather:condition'))
        anchors                 = strfind(buffer,'"');
        current.weather         = buffer(anchors(1) + 1:anchors(2) - 1);
        current.temperature     = [buffer(anchors(5) + 1:anchors(6) - 1), char(176), 'C'];
        current.currentDate     = buffer(anchors(7) + 1:anchors(8) - 1);
    elseif(strfind(buffer, 'yweather:forecast'))
        anchors                 = strfind(buffer, '"');
        frcst(ind).day       = buffer(anchors(1) + 1:anchors(2) - 1);
        frcst(ind).high      = [buffer(anchors(7) + 1:anchors(8) - 1), char(176), 'C'];
        frcst(ind).low       = [buffer(anchors(5) + 1:anchors(6) - 1), char(176), 'C'];
        frcst(ind).weather   = buffer(anchors(9) + 1:anchors(10) - 1);
        ind = ind + 1;
        if ind > 3
            flgOut = 1;
        end
    elseif(isempty(buffer)) % Exit if nothing is in the buffer
        flgOut = 1;
        current = nan;
    end
    
end


s=prt(current);
for ii = 1:3
    prt( frcst(ii) );
end


end