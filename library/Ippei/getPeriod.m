function [ period ] = getPeriod( hostname )

switch hostname
    case {'GTX770', 'WS'}       % 13:05 346 30 355
        period = 17;
    case 'GTX670'       % 14:30 381 28 408
        period = 37;
    case 'GTX480'       % 17:24 428 37 496
        period = 67;
    case {'GTX650', 'T3500'}       % 21:29 689 40 494
        period = 97;
    case 'GTS450'       % 27:38 999 47 560
        period = 137;
    otherwise
        period = 197;
end

end

