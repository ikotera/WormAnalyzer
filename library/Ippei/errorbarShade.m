function [hP, hE] = errorbarShade(X, Y, SE, CL, AL, parent)

if ~exist('CL', 'var')
    CL = [0 0 1];
end
if ~exist('AL', 'var')
    AL = 0.5;
end

nn = any( [isnan(X), isnan(Y), isnan(SE)], 2 );
X(nn) = [];
Y(nn) = [];
SE(nn) = [];
SE(SE == 0) = 0.00001;

if exist('parent', 'var')
    hold(parent, 'on');
    hE = fill([X; flipud(X)], [Y + SE; flipud(Y - SE)], CL, 'FaceAlpha', AL, 'linestyle', 'none', 'Parent', parent);
    hP = plot(X, Y, 'Color', CL, 'Parent', parent);
    hold(parent, 'off');
else
    hold on
    hE = fill([X; flipud(X)], [Y + SE; flipud(Y - SE)], CL, 'FaceAlpha', AL, 'linestyle', 'none');
    hP = plot(X, Y, 'Color', CL);
    hold off
end


end