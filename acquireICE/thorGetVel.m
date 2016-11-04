function [maxVelHor, maxVelVer] = thorGetVel(objSer)


countEncoder = 20000;
intervalSampling = 1.0240e-04;
scaling = 2^16;


% MGMSG_MOT_SET_VELPARAMS (Bay 1, horizontal)
fwrite(objSer, uint8(hex2dec(['14';'04';'01';'00';'21';'01';...          % Header
                        ])));
                    
% MGMSG_MOT_SET_VELPARAMS (Bay 2, vertical)
fwrite(objSer, uint8(hex2dec(['14';'04';'01';'00';'22';'01';...          % Header
                        ])));

                    
% java.lang.Thread.sleep(1);

retH = dec2hex(fread(objSer, 20, 'uchar'));
velH = thorHex2dec(retH, 16, 19);
maxVelHor = velH / (countEncoder * intervalSampling * scaling); % Converting to mm/s

retV = dec2hex(fread(objSer, 20, 'uchar'));
velV = thorHex2dec(retV, 16, 19);
maxVelVer = velV / (countEncoder * intervalSampling * scaling); % Converting to mm/s


end