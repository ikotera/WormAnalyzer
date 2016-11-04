function ok

s = getWeather(4118);

prt(char(10));
prt(datestr(now, 'yyyy/mm/dd HH:MM:SS AM'));
prt('-------------------------------------------');

prt('Current Temperature:    ', [s.currentTemp, char(176),'C']);

prt('Current Weather:        ', s.currentWeather);

prt('Weather Forecast:       ', s.forecastWeather);

prt('Forecast Low            ', [s.forecastLow, char(176),'C']);

prt(char(10));

end