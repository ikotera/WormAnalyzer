classdef graphicManager < handle
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        gm________________;
        oTransitions;
        oLengths;
        oOnsets;
        oDurations;
        objAnalysis;
        typeObj;
        numGraphs;
        hBiograph;
        combo =  {1, 2, 'N2/nsy-1';...                                          % N2/nsy-1
                  1, 3, 'N2/nsy-7';...                                          % N2/nsy-7
                  2, 3, 'nsy-1/nsy-7'};                                         % nsy-1/nsy-7
        sizeFont = 16;
        
        ttest;
        ftest;
        statsPlot;
        dataPlot;
    end
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods
        function gm = graphicManager(obj)
            if iscell(obj)                                                      % For objects in cells
                if isa(obj{1}, 'lengthCalculator')
                    gm.typeObj = 'A';
                elseif isa(obj{1}, 'transitionCalculator')
                    gm.typeObj = 'B';
                elseif isa(obj{1}, 'onsetCalculator')
                    gm.typeObj = 'A';
                elseif isa(obj{1}, 'durationCalculator')
                    gm.typeObj = 'A';
                elseif isa(obj{1}, 'fractionCalculator')
                    gm.typeObj = 'C';
                end
                gm.objAnalysis = [obj{:}]';                                     % Convert cell array of objects to regular array
            else                                                                % For naked object
                if isa(obj, 'mutantManager')
                    gm.typeObj = 'M';
                end
                gm.objAnalysis = obj;                                    
            end
        end
%=================================================================================================================================
        function plotHistograms(~, s, titleSP)
            if nargin < 3
                titleSP = '';
            end

            figure('Position', [100 100 900 1100], 'Color', 'w');
            lm = 0.02;
            rm = 1 - lm;
            sz = 0.88;
            
            [blx, bly] = meshgrid( lm:rm/s.sizeY:rm, lm:rm/s.sizeZ:rm );
            hAxes = arrayfun( @(x,y) axes( 'Position', [x, y, sz/s.sizeY, sz/s.sizeZ] ), blx, bly, 'UniformOutput', false );
            suptitle([titleSP, char(10)]);
            

            for z = 1:s.sizeZ
                for y = 1:s.sizeY
                    axes(hAxes{s.sizeZ - z + 1, y});
%                     subplot(s.sizeZ, s.sizeY, n);


                    hold on
%                     histNorm(s.data(:, y, z), 'LegendStats', [-2, s.xtick']);
                    histNorm(s.data(:, y, z));
                    xlim([0 inf]);
                    title([s.titles{1}{y}, ', ', s.titles{2}{z}]);
                    hold off
                end
            end

        end
%=================================================================================================================================
        function s = plotND(gm, s, titleSP)
            if nargin < 3
                titleSP = '';
            end
            
            nameVar = {'Plot', 'Xtick', 'Data', 'Mean', 'SD', 'SE', 'CI83', 'NumWorms', 'Median', 'P25', 'P75'};
            cs = cell( s.sizeX * s.sizeY * s.sizeZ, numel(nameVar) );
%             s.stats = cell2table(cs);
            
            s.hF = figure('Position', s.posFig, 'Color', 'w',...
                'DefaultAxesFontSize', 11, 'defaultTextFontName', 'Arial');
            suptitle([titleSP, char(10)]);
            pl = 1;
            dp = 1;
            cl = [.85 .85 .95];
            
            for z = 1:s.sizeZ
                for y = 1:s.sizeY
                    s.hS{y, z} = subplot(s.sizeZ, s.sizeY, pl);

                    hold on
                    if s.flgZebra
                        time = [1.5 1.5 2.5 2.5 3.5 3.5 4.5 4.5 5.5 5.5 6.5 6.5 7.5 7.5 8.5 8.5 9.5 9.5 10.5 10.5];
                        amplitude = [0 1 1 0 0 1 1 0 0 1 1 0 0 1 1 0 0 1 1 0];
                        amplitude = amplitude .* s.maxData(z);
                        hA = area(time, amplitude);
                        hA.FaceColor = [1.0 0.9 0.9]; hA.EdgeColor = 'none'; hA.FaceAlpha = 0.7;
                    end
                    
                    if ~isempty(s.titles)
                        ttl = [s.titles{1}{y}, ', ', s.titles{2}{z}];
                        flgTitle = true;
                    else
                        ttl = pl;
                        flgTitle = false;
                    end
                    
                    for x = 1:s.sizeX
                        
                        if s.flgRawData
                            for p = 1:length(s.data{x, y, z})
                                line(x + (rand(1) - 0.5) * 0.3, s.data{x, y, z}(p), 'Marker', '.', ...
                                    'MarkerFaceColor', cl, 'MarkerEdgeColor', cl);
                            end
                        end  
                        
                        switch s.typePlot
                            case 'bar'
                                s.hD{x, y, z} = bar(x, s.mean(x, y, z), 'FaceColor', s.colors{x},...
                                    'EdgeColor', 'black', 'LineWidth', 0.9);
                                s.hE{x, y, z} = errorbar(x, s.mean(x, y, z), s.CI83(x, y, z), 'Color', 'black', 'LineWidth', 0.9);
                            case 'marker'

                                if x == 1 && ~isempty(s.widthLine)
                                    line(1:s.sizeX, s.mean(:, y, z), 'LineWidth', s.widthLine, 'Color', [0.85 0.85 0.95]);
                                end

                                s.hD{x, y, z} = line(x, s.mean(x, y, z), 'Marker', s.markers{x}, 'MarkerSize', s.sizeMarker,...
                                    'MarkerFaceColor', s.colors{x}, 'MarkerEdgeColor', s.colors{x});
                                s.hE{x, y, z} = terrorbar(x, s.mean(x, y, z), s.CI83(x, y, z), s.CI83(x, y, z),...
                                    s.widthErrorbar, 'units');
                                line(x, s.mean(x, y, z), 'Marker', 'o', 'MarkerSize', 2,...
                                    'MarkerFaceColor', 'k', 'MarkerEdgeColor', 'k');
                                
                            case 'median'
                                if x == 1 && ~isempty(s.widthLine)
                                    line(1:s.sizeX, s.median(:, y, z), 'LineWidth', s.widthLine, 'Color', [0.85 0.85 0.95]);
                                end
                                s.hE{x, y, z} = terrorbar(x, s.median(x, y, z), s.P25(x, y, z), s.P75(x, y, z),...
                                    s.widthErrorbar, 'units');
                                line(x, s.median(x, y, z), 'Marker', 'o', 'MarkerSize', 2,...
                                    'MarkerFaceColor', 'k', 'MarkerEdgeColor', 'k');
                            case 'boot'
%                                 if x == 1 && ~isempty(s.widthLine)
%                                     line(1:s.sizeX, s.median(:, y, z), 'LineWidth', s.widthLine, 'Color', [0.85 0.85 0.95]);
%                                 end
                                s.hD{x, y, z} = line(x, s.mean(x, y, z), 'Marker', s.markers{x}, 'MarkerSize', s.sizeMarker,...
                                    'MarkerFaceColor', s.colors{x}, 'MarkerEdgeColor', s.colors{x});
                                s.hE{x, y, z} = terrorbar(x, s.mean(x, y, z), s.BL(x, y, z), s.BH(x, y, z),...
                                    s.widthErrorbar, 'units');
                                line(x, s.mean(x, y, z), 'Marker', 'o', 'MarkerSize', 2,...
                                    'MarkerFaceColor', 'k', 'MarkerEdgeColor', 'k');
                                

                        end
                        
                        cs(dp, :) = {ttl, s.xtick(x), s.data(x, y, z), s.mean(x, y, z), ...
                            s.SD(x, y, z), s.SE(x, y, z), s.CI83(x, y, z), s.count(x, y, z), s.median(x, y, z), s.P25(x, y, z), s.P75(x, y, z)};
                        dp = dp + 1;
                        
                    end
                    
                    switch s.typePlot
                        case 'box'
   
                            for yc = 1:s.sizeX
                                cr{yc, 1} = ones(size(s.data{yc, y, z})) + yc - 1;
                            end
                            sz = size(cr{1});
                            if sz(1) < sz(2)
                                gr = [cr{:}];
                                dt = [s.data{:, y, z}];
                            else
                                gr = cat(1, cr{:})';
                                dt = cat(1, s.data{:, y, z})';
                            end
                                
                                s.hD{1, y, z} = boxplot( dt, gr, 'notch', 'on', 'symbol', '' );
                        case 'violin'
                            s.hE{x, y, z} = violin(s.data{:, y, z});
                    end
                    
                    hold off
                    
                    switch s.typePlot
                        case {'marker', 'bar', 'median', 'boot'}
                            ylabels = linspace( s.minData(z), s.maxData(z), s.numYtick);
                            s.hA{y, z} = gca;
                            set(s.hA{y, z},'XTick', 1:s.sizeX, 'XTickLabel', s.xtick, 'XTickLabelRotation', s.rotationXTick);
                            set(s.hA{y, z},'YTick',  ylabels);
                            
                            format = repmat( {['%#3.', num2str( s.roundYtick(z) ), 'f']}, size(ylabels) );
                            cLabel =  cellfun(@num2str, num2cell(ylabels), format, 'uni', 0);
                            set( s.hA{y, z},'YTickLabel', cLabel);
                    end
                    

                    
                    xlim([0.1, s.sizeX + 0.9]);
                    ylim( [s.minData(z) s.maxData(z)] );
%                     set(gca,'yscale','log');
                    if flgTitle, title(ttl); end
                    
                    sp(pl, 1) = ntests( s.data(:, y, z) );

                    pl = pl + 1;
                end
            end
            gm.statsPlot = sp;
            gm.dataPlot = cell2table(cs);
            gm.dataPlot.Properties.VariableNames = nameVar;
            
%             cl = m.extractCell('data', 'fractions', 'b');
%             cl = squeeze(cl(:, 2, :));
%             
%             for b = 1:3
%                 st(b) = ntests(cl(:,b));
%             end
        end
%=================================================================================================================================
        function saveStats(gm, namePath, nameFile)
            stats.dataPlot = gm.dataPlot;
            stats.statsPlot = gm.statsPlot;
            save([namePath, '\', nameFile], 'stats');
        end
%=================================================================================================================================
        function imageBehaviors(gm)
            
            for m = 1:gm.objAnalysis.nMutants
                figure('Position', [100 100 900 1000], 'Color', 'w');
                suptitle([gm.objAnalysis.listM{m}, char(10)]);
                n = 1;
                for p = [1,2:1:gm.objAnalysis.nPhases]
                    subplot(1, gm.objAnalysis.nPhases, n);
                    imagesc(gm.objAnalysis.mutants(m).phases(p).matrixBehavior'); caxis([0 4]);
                    bm = behaviorManager;
                    colormap(bm.colormapBehavior);
                    title(gm.objAnalysis.listP{p});
                    n = n + 1;
                end
            end
        end
%=================================================================================================================================
%         function s = prepareTransitionData(gm, str, phase)
%             mm = gm.checkObj(gm.objAnalysis, 'M');
%             
%             s.idxP = find( strcmp(phase, mm.listP) );
%             s.phase = phase;
%             
%             [M, ~, ~] = mm.getSizes;
% 
%             mean = mm.extractCell('mean', str);
%             data = mm.extractCell('data', str);
%             CI83 = mm.extractCell('CI83', str);
% 
%             adj = mm.extractCell([], 'adjacencyMatrix');
%             [r, c] = mm.adj2sub(adj);
%             T = size(r, 1);
%             titlesLengths = cell(M, T);
%             titlesRates = cell(M, T);
%              
%             for t = 1:T
%                 for m = 1:M
%                     for p = 1:size(mean, 2)
%                         dt{p, m, t} = data{m, p}{ r(t), c(t) };
%                         mn(p, m, t) = mean{m, p}( r(t), c(t) );
%                         er(p, m, t) = CI83{m, p}( r(t), c(t) );
%                     end
%                     titlesLengths{m, t} = [mm.listM{m}, ', ', mm.listB{r(t)}, ' -> ', mm.listB{c(t)}];
%                     titlesRates{m, t} = [mm.listB{r(t)}, ' -> ', mm.listB{c(t)}];
%                 end
%             end
%             
%             s.data = dt;
%             s.mean = mn;
%             s.CI83 = er;
%             s.sizeM = M;
%             s.sizeB = T;
%             s.titles = titlesLengths;
%             s.titlesR = titlesRates;
%             s.colors = [{'b'}, repmat({'r', 'g'}, 1, 5)];
%             topData = s.mean(:, :, :) + s.CI83(:, :, :);
%             bottomData = s.mean(:, :, :) - s.CI83(:, :, :);
%             s.maxData = squeeze( max( max(topData, [], 1), [], 2) ) .* 1.1;
%             s.minData = squeeze( min( min(bottomData, [], 1), [], 2) ) .* 0.9;
%             s.maxRate = squeeze( max( max(topData(s.idxP, :, :), [], 1), [], 2) ) .* 1.1;
%             s.minRate = squeeze( min( min(bottomData(s.idxP, :, :), [], 1), [], 2) ) .* 0.9;
%             s.mutants = mm.listM;
%         end
%=================================================================================================================================
%         function s = preparePlotData(gm, strD, strE)
%             
%             mm = gm.checkObj(gm.objAnalysis, 'M');            
%             
%             if nargin == 1
%                 s.mean = mm.extractMatrix('mean');
%                 s.CI83 = mm.extractMatrix('CI83');
%             elseif nargin == 2
%                 s.mean = mm.extractMatrix(strD);
%                 s.CI83 =  zeros( size(s.mean) );
%             elseif nargin == 3
%                 s.mean = mm.extractMatrix(strD);
%                 s.CI83 = mm.extractMatrix(strE);
%             end
%             
% %             s.data = mm.extractCell('data', str);
%             
%             [M, ~, B] = mm.getSizes;
%             s.titles = cell(M, B);
%             for b = 1:B
%                 for m = 1:M
%                     s.titles{m, b} = [mm.listM{m}, ', ', mm.listB{b}];
%                 end
%             end
% 
%             s.sizeM = M;
%             s.sizeB = B;
%             s.colors = [{'b'}, repmat({'r', 'g'}, 1, 5)];
%             topData = s.mean + s.CI83;
%             bottomData = s.mean - s.CI83;
%             s.maxData = squeeze( max( max(topData, [], 1), [], 2) );
%             s.minData = squeeze( min( min(bottomData, [], 1), [], 2) );
%             s.maxData = s.maxData + s.maxData .* 0.1;
%             s.minData = s.minData - s.minData .* 0.1;
%             s.minData(s.minData < 0) = 0;
%             
%         end
%=================================================================================================================================
%         function plotTransitionRates(~, s)
%             
%             figure('Position', [100 100 900 250], 'Color', 'w');
%             suptitle([s.phase, char(10)]);
%             n = 1;
%             p = s.idxP;
%             for b = 1:s.sizeB
%                 subplot(1, s.sizeB, n);
%                 
%                 n = n + 1;
%                 hold on
%                 for m = 1:s.sizeM
%                     bar( m, s.mean(p, m, b), 'FaceColor', s.colors{p});
% %                     line(m, s.data{p, m, b}, 'Marker', '.');
%                     errorbar(m, s.mean(p, m, b), s.CI83(p, m, b), 'k', 'LineStyle', 'none' );
%                 end
%                 hold off
%                 set(gca,'XTickLabel', s.mutants);
%                 xlim([0.1, s.sizeM + 0.9]);
%                 ylim([0 max(s.maxRate)]);
% %                 ylim([0 25]);
%                 title(s.titlesR{m, b});
%             end
%         end
%=================================================================================================================================
        function ntests(gm, obj)
%             obj = mg.checkObj(obj, {'A', 'C'});
            switch class(obj)
                case 'lengthCalculator'
%                     V = {obj.meanPerWorm};                            % Per-worm-based
                    V = {obj.lengthsPerBehav};                          % All events together per each behavior
                case 'fractionCalculator'
                    V = {obj.fractionsPerWorm};
                case 'onsetCalculator'
                    V = {obj.meanPerWorm}; 
            end

            C = gm.combo;
            
            for id = 1:size(C, 1)
                [f(id).h, f(id).p, f(id).ci, f(id).stats] =...
                    vartest2(V{C{id, 1}}, V{C{id, 2}});                 % Two-sample F-test for variance validity
                if isnan(f(id).h)                                       % If F-test failed, likely missing behavior
                    t(id).h = 0; t(id).p = 1; t(id).ci = nan; t(id).stats = nan;
                elseif ~f(id).h                                         % If F-test is NOT rejected, ie, equal variance
                    [t(id).h, t(id).p, t(id).ci, t(id).stats] =...
                        ttest2(V{C{id, 1}}, V{C{id, 2}});               % Two-sample t-test (equal variance)
                    vr = 'equal variance';
                else
                    [t(id).h, t(id).p, t(id).ci, t(id).stats] =...
                        ttest2(V{C{id, 1}}, V{C{id, 2}},...
                        'Vartype', 'unequal');                          % Two-sample t-test (unequal variance)
                    vr = 'unequal variance';
                end
                
                gm.ttest = t;
                gm.ftest = f;
%                 prt('%0.5f', C{id, 3}, '\ns,', vr, '\ns, p =', t(id).p);
            end
        end
%=================================================================================================================================
        function makeGraph(gm)
            ot = gm.checkObj(gm.objAnalysis, 'B');
            
            gm.numGraphs = numel(ot);
            
            for n = 1:gm.objAnalysis(1).numBehaviors
                o = arrayfun(@(x) gm.objAnalysis(x).objLengths(n), 1:3, 'Un', false);
                obj(n, :) = [o{:}];
            end

            factorScale = 3;
            minScale = 1.5;
            for g = 1:gm.numGraphs
                sp = sparse(ot(1).probabilityMatrix);                           % Use the first matrix to make all the graphs
                bg = biograph(sp, ot(g).behaviors,...
                    'LayoutType', 'hierarchical', 'ShowWeights','on');          % Construct biograph objects

                hG = biograph.bggui(bg);                                        % Use this hack to access hidden objects
                                                                                % IMPORTANT: For MATLAB R2014b and later,
                                                                                % see notes at the bottom

                close(hG.hgFigure);
                bb = hG.biograph;
                
                
                wt = ot(g).probabilityMatrix';                                  % Switch row-col order
                [r, c] = find(wt < 0.0000 & wt > 0);
                for d = 1:numel(r)
                    wt(r(d), c(d)) = 0;                                         % Round to 0 if below threshold
                    bb = edge_del(bb, r(d), c(d));                              % Delete those edges
                end
                
                wt = wt(:);                                                     % Vectorize the matrix
                wt(wt == 0) = [];                                               % Get rid of 0s
                lw = floor( (wt - minScale) * factorScale + 1 );                % Scale to min/max integers
                lw(lw < 1) = 1;
                lw(isnan(lw)) = 1;
                for e = 1:numel(bb.Edges)                                       % Change weights and linewidths
                        bb.Edges(e).Weight = round(wt(e) * 100) / 100;
                        bb.Edges(e).LineWidth = lw(e);
                end
                
                for n = 1:numel(bb.Nodes)                                       % Change node names
                    star = '';
                    gm.ntests(obj(n, :));
                    if g >= 2
                        if gm.ttest(g-1).p <= 0.05 && gm.ttest(g-1).p > 1E-2
                            star = '*';
                        elseif gm.ttest(g-1).p <= 1E-2 && gm.ttest(g-1).p > 1E-3
                            star = '**';
                        elseif gm.ttest(g-1).p <= 1E-3
                            star = '***';
                        end
                    end
                    
                    bb.Nodes(n).ID = [ot(g).behaviors{n}, ' ',...
                        num2str(ot(g).objLengths(n).meanPerBehav, '%2.1f'), star];

                end
                
                hBb = biograph.bggui(bb);
                f = figure;
                copyobj(hBb.biograph.hgAxes, f);
                text(60, 172, ot(g).nameMutant, 'FontSize', 14);
                close(hBb.hgFigure);
                gm.hBiograph{g} = bg;
            end
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Access = protected)
        
        function obj = checkObj(gm, obj, typeObj)
            if all( ~strcmp(gm.typeObj, typeObj) )
                error(['This method requires type ', typeObj, ' instance.']);
            elseif isempty(obj)
                error('A required instance was not found for this method.');
            end
        end
        
    end
    
end



% IMPORTANT NOTES:

% Delete line 34 of hgCorrectFontSize.m

% set(mycell2mat(get(mycell2mat(get(h.Edges,'hgline')),'UserData')),'FontSize',edgeFontSize)

% And add the following instead:

% ln = get(h.Edges,'hgline');
% for l = 1:numel(ln)
%     set(get(ln{l}, 'UserData'),'FontSize',edgeFontSize);
% end



%#ok<*AGROW>

