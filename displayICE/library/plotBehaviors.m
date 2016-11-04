function hLs = plotBehaviors(hA, hLs, behaviors)

if ~issafe('hA'), return, end                                        % Update the behavior plot
if issafe('hLs')
    arrayfun(@(h) delete(h), hLs);
end

flgFirst = true;
sizeBeh =length(behaviors);
hLs = nan(sizeBeh, 1);
idx = 1;
flgPlot = false;

for c = 2:sizeBeh                           % Loop through all the elements in behavior vector
    if flgFirst
        beh = nan(sizeBeh, 1);
        beh(c-1) = behaviors(c-1);
        valP = behaviors(c-1);
        flgFirst = false;
    end
    
    valC = behaviors(c);
    if valP == valC                         % If previous and current elements are the same
        beh(c) = behaviors(c);              % Add one elemet to a new vector for plotting
        if ~isnan(valP) && c == sizeBeh
            flgPlot = true;
        end
    elseif ~isnan(valP) && valP ~= valC     % Else if real number to real number transitions
        flgPlot = true;
    end
    
    if flgPlot
        X = find( ~isnan(beh) );            % Indeces of non-NaN values
        X = [X; X(end)+1]; %#ok<AGROW>      % Add one extra at the end of the vector to avoid gaps between lines
        Y = ones(size(X));
        
        if valP == 1                        % 'forward'
            hLs(idx) = line(X, Y, 'LineWidth', 50, 'Color', [0.3 1 0.3], 'Parent', hA);
        elseif valP == 2                    % 'reverse'
            hLs(idx) = line(X, Y, 'LineWidth', 50, 'Color', [1 0.3 0.3], 'Parent', hA);
        elseif valP == 3                    % 'turn'
            hLs(idx) = line(X, Y, 'LineWidth', 50, 'Color', [0.5 0.5 1], 'Parent', hA);
        elseif valP == 4                    % 'pause'
            hLs(idx) = line(X, Y, 'LineWidth', 50, 'Color', [1 1 0.3], 'Parent', hA);
        end
        idx = idx + 1;
        flgFirst = true;
        flgPlot = false;
    end
    valP = valC;
end

hLs( isnan(hLs) ) = [];                     % Remove NaNs from handles vector

end