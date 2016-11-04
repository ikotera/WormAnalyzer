function nc = bprt(varargin)

% nc = bprt(str1, str2,... nc) will recursively print strings to command window. Put 0 to nc for the
% first call and nc should stay in workspace to store number of characters previously printed.


nc = varargin{end};

if nc == 0
    str = prt([' ', varargin{1, 1:end - 1}]);
    nc = numel(str) + 1;
else
    c = repmat(char(8), 1, nc);
    c = [{c}, varargin(1, 1:end - 1)];
    str = prt(c{:});
    nc = numel(str) - nc + 1;
end

end