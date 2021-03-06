function table = behavior(m)

if ~exist('m', 'var')
    m = 5;
end

table = cat(1, ...
[1      1       1  ], ...    
[0.3    1       0.3], ...
[1      0.3     0.3], ...
[0.5    0.5     1  ], ...
[.9      .9       0.3]  ...
 );

table = table(end-m+1:end, :);