function s = getWeather(WOEID)

if ~exist('WOEID', 'var')
    WOEID = 4118;
end

% Toronto = '4118';
URL = ['http://weather.yahooapis.com/forecastrss?w=' num2str(WOEID) '&u=c'];

% Open connection to Yahoo weather API 
url     = java.net.URL(URL);       % Construct a URL object
is      = openStream(url);              % Open a connection to the URL
isr     = java.io.InputStreamReader(is);
br      = java.io.BufferedReader(isr);

% Look for the following tags and acquire the text info
flgOut = 0;
while(flgOut ~= 1)
    buffer = char(readLine(br));
    if(strfind(buffer, 'yweather:location'))
        anchors           = strfind(buffer,'"');
        s.city            = buffer(anchors(1) + 1:anchors(2) - 1);
        s.region          = buffer(anchors(3) + 1:anchors(4) - 1);
        s.country         = buffer(anchors(5) + 1:anchors(6) - 1);
    elseif(strfind(buffer, 'yweather:wind'))
        anchors           = strfind(buffer,'"');
        s.currentWindchill= buffer(anchors(1) + 1:anchors(2) - 1);
        s.currentWindspeed= buffer(anchors(5) + 1:anchors(6) - 1);
    elseif(strfind(buffer, 'yweather:atmosphere'))
        anchors           = strfind(buffer,'"');
        s.currentHumidity = buffer(anchors(1) + 1:anchors(2) - 1);
        s.currentPressure = buffer(anchors(5) + 1:anchors(6) - 1);
        s.currentRising   = buffer(anchors(7) + 1:anchors(8) - 1);
    elseif(strfind(buffer, 'yweather:astronomy'))
        anchors           = strfind(buffer,'"');
        s.currentSunrise  = buffer(anchors(1) + 1:anchors(2) - 1);
        s.currentSunset   = buffer(anchors(3) + 1:anchors(4) - 1);
    elseif(strfind(buffer, 'yweather:condition'))
        anchors           = strfind(buffer,'"');
        s.currentWeather  = buffer(anchors(1) + 1:anchors(2) - 1);
        s.currentTemp     = buffer(anchors(5) + 1:anchors(6) - 1);
        s.currentDate     = buffer(anchors(7) + 1:anchors(8) - 1);
    elseif(strfind(buffer, 'yweather:forecast'))
        anchors           = strfind(buffer, '"');
        s.forecastWeather = buffer(anchors(9) + 1:anchors(10) - 1);
        s.forecastHigh    = buffer(anchors(7) + 1:anchors(8) - 1);
        s.forecastLow     = buffer(anchors(5) + 1:anchors(6) - 1);
        s.forecastDay     = buffer(anchors(1) + 1:anchors(2) - 1);
        s.forecastDate    = buffer(anchors(3) + 1:anchors(4) - 1);
        flgOut = 1;
    elseif(isempty(buffer)) % Exit if nothing is in the buffer
        flgOut = 1;
        s = nan;
    end
    
end

