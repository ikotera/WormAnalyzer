function thorSetJog(objSer, velocityHor, velocityVer, stepHor, stepVer)


countEncoder = 20000;
intervalSampling = 1.0240e-04;
scaling = 2^16;

velAptHor = round(countEncoder * intervalSampling * scaling * velocityHor);
velAptVer = round(countEncoder * intervalSampling * scaling * velocityVer);
hexH = thorDec2hex(velAptHor, 8);
hexV = thorDec2hex(velAptVer, 8);

stepHor = round(stepHor * countEncoder);
stepVer = round(stepVer * countEncoder);
stepH = thorDec2hex(stepHor, 8);
stepV = thorDec2hex(stepVer, 8);


% MGMSG_MOT_SET_VELPARAMS (Bay 1, horizontal)
fwrite(objSer, uint8(hex2dec(['16';'04';'16';'00';'A1';'01';...         % Header
                         '01';'00';...                                  % Chan Ident
                         '01';'00';...                                  % Jog Mode
                         stepH(1:2);stepH(3:4);stepH(5:6);stepH(7:8);...% Jog Step Size
                         '00';'00';'00';'00';...                        % Jog Min Velocity
                         'B0';'35';'00';'00';...                        % Jog Acceleration
                         hexH(1:2);hexH(3:4);hexH(5:6);hexH(7:8);...    % Jog Max Velocity
                         '02';'00';...                                  % Jog Stop Mode
                        ])));
                    
% MGMSG_MOT_SET_VELPARAMS (Bay 2, horizontal)
fwrite(objSer, uint8(hex2dec(['16';'04';'16';'00';'A2';'01';...         % Header
                         '01';'00';...                                  % Chan Ident
                         '01';'00';...                                  % Jog Mode
                         stepV(1:2);stepV(3:4);stepV(5:6);stepV(7:8);...% Jog Step Size
                         '00';'00';'00';'00';...                        % Jog Min Velocity
                         'B0';'35';'00';'00';...                        % Jog Acceleration
                         hexV(1:2);hexV(3:4);hexV(5:6);hexV(7:8);...    % Max Velocity
                         '02';'00';...                                  % Jog Stop Mode
                        ])));

% pause(0.05);
% s.BytesAvailable

end