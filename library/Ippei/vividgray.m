function gr = vividgray(maxMin)

% 1          mx
%           /
%          /
%         /
%   _____/
% 0      mn

mx = round(maxMin(1) - 1);
mn = round(maxMin(2) - 1);

gr = ([zeros(1, mn), 0:mx])'/max(mx, 1);
gr = [gr gr gr];

end