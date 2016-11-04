function thorMovRel(s, disX, disY)

% Moves Thorlabs XY stage in relative distances.
% s, serial object of the stage
% disX, distance to move horizontally in nm
% disY, distance to move vertically in nm

countPerNM = 0.02;

hexX = thorDec2hex(round(disX * countPerNM), 8);
hexY = thorDec2hex(round(disY * countPerNM), 8);

%% MGMSG_MOT_MOVE_RELATIVE (X)
fwrite(s, uint8(hex2dec(['48';'04';'06';'00';'A1';'01';'01';'00';...
                         hexX(1:2);hexX(3:4);hexX(5:6);hexX(7:8);...
                        ])));

%% MGMSG_MOT_MOVE_RELATIVE (Y)
fwrite(s, uint8(hex2dec(['48';'04';'06';'00';'A2';'01';'01';'00';...
                         hexY(1:2);hexY(3:4);hexY(5:6);hexY(7:8);...
                        ])));

end