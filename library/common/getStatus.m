function st = getStatus

try
    st.now = now;
    [~, day] = weekday(date, 'long');
    st.nowStr = [datestr(now,'yyyy/mm/dd'), ' ', day, ' ', datestr(st.now,'HH:MM:SS AM')];
    [~, hostname] = system('hostname');
    st.hostname = strtrim(hostname);
    [~, username] = system('whoami');
    st.username = strtrim(username);
    st.stack = dbstack('-completenames');
    sw = gw;
    st.city = sw.city;
    st.currentTemp = sw.currentTemp;
    st.currentWeather = sw.currentWeather;
    st.currentPressure = sw.currentPressure;
    st.currentHumidity = sw.currentHumidity;
catch err
    st.err = err;
end


end