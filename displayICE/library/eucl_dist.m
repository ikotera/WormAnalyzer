function d = eucl_dist(x1,y1,x2,y2)
% d = eucl_dist(x1,y1,x2,y2)
%
% Receives four numbers indicating two points (x1,y1) and (x2,y2)
% Returns the Euclidean distance between those two points (d)

d = sqrt((x1 - x2)^2 + (y1 - y2)^2);