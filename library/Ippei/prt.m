function strPrt = prt(varargin)

% PRT(X) concatnates all the input arguments with single spaces inbetween, and displays the
% concatenated string using fprintf function. Numbers are converted to strings with 2 decimal digits
% at default. If the first input argument starts with '%', then that argument is interpreted as a
% format for sprintf conversion.


if strcmp(varargin{1}(1), '%')                                  % Check if the first argument starts with '%'
    fmt = varargin{1};                                          % It's a format for sprintf
    flgFmt = 1;
else
    fmt = '%0.2f';                                              % Default string conversion format
    flgFmt = 0;
end

strPrt = [];

for na = 1 + flgFmt:nargin                                      % Start with the second argument if the first is a format
    if isnumeric(varargin{na})
        if rem(varargin{na}, 1) == 0                            % If integer
            varargin{na} = num2str(varargin{na});               % Number is converted to str without decimal
        else
            varargin{na} = sprintf(fmt, varargin{na});          % Number is converted to string using fmt
        end
    elseif islogical(varargin{na})                              % Convert it to string if it's logical
        if varargin{na}
            varargin{na} = 'true';
        else
            varargin{na} = 'false';
        end
    end
    if na == 1 + flgFmt
        strPrt = varargin{na};                                  % The first argument is added without space
    else
        if ~strcmp( varargin{na}, ' ' ) &&...                   % Add space inbetween arguments if it's not a space
                ~strcmp( varargin{na-1}, char(10) )             % nor previous was a carriage return
            if length(varargin{na-1}) >= 3 &&...
                    strcmp(varargin{na-1}(end-2:end), '\ns')    % No space is added if the prevoius ended with '\ns'
                strPrt = [strPrt(1:end-3), varargin{na}];  
            elseif length(varargin{na}) >= 3 &&...
                    strcmp(varargin{na}(1:3), '\ns')            % or current starts with '\ns'
                strPrt = [strPrt, varargin{na}(4:end)];         %#ok<AGROW>
            else
                strPrt = [strPrt, ' ', varargin{na}];           %#ok<AGROW>
            end
        else
            strPrt = [strPrt, varargin{na}];                    %#ok<AGROW>
        end
    end
end

disp(strPrt);
