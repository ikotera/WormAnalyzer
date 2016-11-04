function thorSetVel(objSer, velocityHor, velocityVer)


countEncoder = 20000;
intervalSampling = 1.0240e-04;
scaling = 2^16;

velAptHor = round(countEncoder * intervalSampling * scaling * velocityHor);
velAptVer = round(countEncoder * intervalSampling * scaling * velocityVer);

hexH = thorDec2hex(velAptHor, 8);
hexV = thorDec2hex(velAptVer, 8);

% MGMSG_MOT_SET_VELPARAMS (Bay 1, horizontal)
fwrite(objSer, uint8(hex2dec(['13';'04';'0E';'00';'A1';'01';...         % Header
                         '01';'00';...                                  % Chan Ident
                         '00';'00';'00';'00';...                        % Min Velocity
                         'B0';'35';'00';'00';...                        % Acceleration
                         hexH(1:2);hexH(3:4);hexH(5:6);hexH(7:8);...    % Max Velocity
                        ])));
                    
% MGMSG_MOT_SET_VELPARAMS (Bay 2, horizontal)
fwrite(objSer, uint8(hex2dec(['13';'04';'0E';'00';'A2';'01';...         % Header
                         '01';'00';...                                  % Chan Ident
                         '00';'00';'00';'00';...                        % Min Velocity
                         'B0';'35';'00';'00';...                        % Acceleration
                         hexV(1:2);hexV(3:4);hexV(5:6);hexV(7:8);...    % Max Velocity
                        ])));


% pause(0.05);
% s.BytesAvailable

end