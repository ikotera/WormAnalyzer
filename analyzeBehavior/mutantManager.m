classdef mutantManager < handle
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        mm________________;
        mutants;
        type;
        flgIgnoreFirstState = false;
        flgIgnoreLastState = false;
        flgCountNonTransition = true;
        secondsToAnalyze = 25;
        threshMinLength = 0.5;
        nPhases;
        nBehaviors;
        nMutants;
        listP;
        listB;
        listM;
    end
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods        
        function mm = mutantManager(df, type)
            mm.nPhases = df(1).nPhases;         P = mm.nPhases;
            mm.nBehaviors = df(1).nBehaviors;   B = mm.nBehaviors;
            mm.nMutants = size(df, 1);          M = mm.nMutants;
            mm.type = type;
            mm.listP = df(1).listP(:, 1);
            mm.listB = df(1).listB;
            
            param.flgIgnoreFirstState = mm.flgIgnoreFirstState;
            param.flgIgnoreLastState = mm.flgIgnoreLastState;
            param.flgCountNonTransition = mm.flgCountNonTransition;
            param.secondsToAnalyze = mm.secondsToAnalyze;
            param.threshMinLength = mm.threshMinLength;
            
            for m = 1:M
                mm.listM{m, 1} = df(m, 1).nameMutant;
                for p = 1:P 
                    switch type                                             	% Select appropriate class to be instantiated
                        case 'transitions'
                            mm.mutants(m, 1).phases(p, 1) = transitionCalculator(df(m), p, param);
                        case 'lengths'
                                mm.mutants(m, 1).phases(p, 1) = lengthCalculator(df(m), p, param);
                        case 'fractions'
                                mm.mutants(m, 1).phases(p, 1) = fractionCalculator(df(m), p, param);
                        case 'onsets'
                                mm.mutants(m, 1).phases(p, 1) = onsetCalculator(df(m), p, param);
                    end
                end
            end
           
        end
%=================================================================================================================================
        function s = preparePlotData(mm, item, order, ranges, flgNorm)

            s.item = item;
            s.order = order;
            s.ranges = ranges;
            typeData = mm.mutants(1).phases(1).(item).type;
            
            cR = [0.8 0.6 0.6];
            cG = [0.6 0.8 0.6];
            cB = [0.6 0.6 0.8];
            cY = [0.8 0.8 0.8];
            
            if length(order) ~= 3
                error('Number of dimension is incorrect');
            end            
            
            pm = [];
            for od = 1:length(order)
                switch order(od)
                    case 'm'
                        em = 1:mm.nMutants;
                        pm = [pm 1];
                        s.M = eval(['em(', ranges{od}, ')'] );                    
                    case 'p'
                        em = 1:mm.nPhases; %#ok<*NASGU>
                        s.P = eval(['em(', ranges{od}, ')'] );
                        pm = [pm 2];

                    case 'b'
                        em = 1:mm.nBehaviors;
                        pm = [pm 3];
                        s.B = eval(['em(', ranges{od}, ')'] );
                end
            end
            
            switch order(1)
                case 'p'
                    colors = [{cG}, repmat({cR, cB}, 1, 5)];
                    s.colors = colors(s.P);
                    mks = {'v', 'o', 's', 'o', 's', 'o', 's', 'o', 's', 'o', 's'};
                    s.markers = mks(s.P);
                    ph = {'P', 'H1', 'L1', 'H2', 'L2', 'H3', 'L3', 'H4', 'L4', 'H5', 'L5'};
                    s.xtick = ph(s.P);
%                     s.xtick = mm.listP(s.P);
                case 'm'
                    colors = {cR, cG, cB};
                    s.markers = {'d', 'p', '^'};
                    s.colors = colors(s.M);
                    s.xtick = mm.listM(s.M);
                case 'b'
                    colors = {cG, cR, cB, cY};
                    s.markers = {'v', 'o', 's', 'p'};
                    s.colors = colors(s.B);
                    s.xtick = mm.listB(s.B);
            end

%             switch item
%                 case {'lengthsExit', 'ratesExit'}
%                     mm.type = 'exits';
%             end
            DT = mm.extractCell('data', item, typeData);        
            
            P = length(s.P);
            M = length(s.M);
            B = length(s.B);
            
            switch typeData
                case 't'
                    adj = mm.extractCell([], 'adjacencyMatrix', 't');
                    [r, c] = mm.adj2sub(adj);
                    r = r(s.B);
                    c = c(s.B);
                    T = size(r, 1);
                    dt = cell(M, P, T);
                    mn = nan(M, P, T);
                    ci = nan(M, P, T);
                    md = nan(M, P, T);
                    p25 = nan(M, P, T);
                    p75 = nan(M, P, T);
                    tB = cell(T, 1);
                    z = 1;
                    for t = 1:T
                        if strcmp(order(1), 'b')
                            s.xtick{z} = [ mm.listB{r(t)}(1), ' -> ', mm.listB{c(t)}(1) ];
                        end
                        tB{z} = [mm.listB{r(t)}, ' -> ', mm.listB{c(t)}];
                        z = z + 1;
                    end
                case 'b'
                    dt = cell(M, P, B);
                    mn = nan(M, P, B);
                    ci = nan(M, P, B);
                    tB = mm.listB(s.B);
                    md = nan(M, P, B);
                    p25 = nan(M, P, B);
                    p75 = nan(M, P, B);
            end

            switch typeData
                case {'t', 'b'}
                    MN = mm.extractCell('mean', item, typeData);
                    CT = mm.extractCell('count', item, typeData);
                    SD = mm.extractCell('SD', item, typeData);
                    SE = mm.extractCell('SE', item, typeData);
                    CI = mm.extractCell('CI83', item, typeData);
                    MD = mm.extractCell('median', item, typeData);
                    P25 = mm.extractCell('P25', item, typeData);
                    P75 = mm.extractCell('P75', item, typeData);
                    BL = mm.extractCell('bootL', item, typeData);
                    BH = mm.extractCell('bootH', item, typeData);
                    
                    x = 1;
                    for m = s.M
                        y = 1;
                        for p = s.P

                            switch typeData
                                case 't'
                                    z = 1;
                                    for t = 1:T
                                        dt{x, y, z} = DT{m, p}{ r(t), c(t) };
                                        mn(x, y, z) = MN{m, p}( r(t), c(t) );
                                        ct(x, y, z) = CT{m, p}( r(t), c(t) );
                                        sd(x, y, z) = SD{m, p}( r(t), c(t) );
                                        se(x, y, z) = SE{m, p}( r(t), c(t) );
                                        ci(x, y, z) = CI{m, p}( r(t), c(t) );
                                        md(x, y, z) = MD{m, p}( r(t), c(t) );
                                        p25(x, y, z) = P25{m, p}( r(t), c(t) );
                                        p75(x, y, z) = P75{m, p}( r(t), c(t) );
                                        bl(x, y, z) = BL{m, p}( r(t), c(t) );
                                        bh(x, y, z) = BH{m, p}( r(t), c(t) );
                                        
                                        z = z + 1;
                                    end
                                case 'b'
                                    z = 1;
                                    for b = s.B
                                        dt{x, y, z} = DT{m, p, b};
                                        mn(x, y, z) = MN{m, p, b};
                                        ct(x, y, z) = CT{m, p, b};
                                        sd(x, y, z) = SD{m, p, b};
                                        se(x, y, z) = SE{m, p, b};
                                        ci(x, y, z) = CI{m, p, b};
                                        md(x, y, z) = MD{m, p, b};
                                        p25(x, y, z) = P25{m, p, b};
                                        p75(x, y, z) = P75{m, p, b};
                                        bl(x, y, z) = BL{m, p, b};
                                        bh(x, y, z) = BH{m, p, b};
                                        
                                        z = z + 1;
                                    end                                    
                            end
                            y = y + 1;
                        end
                        x = x + 1;
                    end
                    
                    DT = dt; MN = mn; CT = ct; SD = sd; SE = se; CI = ci;
                    MD = md; P25 = p25; P75 = p75; BL = bl; BH = bh;
                    
                otherwise
                    
                    MN = mm.extractMatrix('mean');
                    CI = mm.extractMatrix('CI83');
                    DT = DT(s.M, s.P, s.B);
                    MN = MN(s.M, s.P, s.B);
                    CI = CI(s.M, s.P, s.B);
                    tB = mm.listB(s.B);
            end
            

            tP = mm.listP(s.P);
            tM = mm.listM(s.M);

            [s.sizeM, s.sizeP, s.sizeB] = size(DT);
 
            if ~strcmp(order, 'mpb')
                DT = permute(DT, pm);
                MN = permute(MN, pm);
                CT = permute(CT, pm);
                SD = permute(SD, pm);
                SE = permute(SE, pm);
                CI = permute(CI, pm);
                MD = permute(MD, pm);
                P25 = permute(P25, pm);
                P75 = permute(P75, pm);
                BL = permute(BL, pm);
                BH = permute(BH, pm);
            end
            
            [s.sizeX, s.sizeY, s.sizeZ] = size(DT);
            
            for od = [2 3]
                switch order(od)
                    case 'p'
                        s.titles{od - 1} = tP;
                    case 'm'
                        s.titles{od - 1} = tM;
                    case 'b'
                        s.titles{od - 1} = tB;
                end
            end

            if flgNorm
                CI = CI ./ repmat(MN(1, :, :), s.sizeX, 1, 1);
                MN = MN ./ repmat(MN(1, :, :), s.sizeX, 1, 1);
            end
            
            s.data = DT;
            s.mean = MN;
            s.count = CT;
            s.SD = SD;
            s.SE = SE;
            s.CI83 = CI;
            s.median = MD;
            s.P25 = P25;
            s.P75 = P75;
            s.BL = BL;
            s.BH = BH;

            s.transitions = tB;
            topData = s.mean(:, :, :) + s.CI83(:, :, :);
            bottomData = s.mean(:, :, :) - s.CI83(:, :, :);
            s.maxData = squeeze( max( max(topData, [], 1), [], 2) );
            s.minData = squeeze( min( min(bottomData, [], 1), [], 2) );
            range = s.maxData - s.minData;
            s.maxData = s.maxData + range * 0.13;
            s.minData = s.minData - range * 0.13;
            s.minData(s.minData < 0) = 0;
            
            s.maxMean = squeeze( max( max(s.mean, [], 1), [], 2) );
            s.minMean = squeeze( min( min(s.mean, [], 1), [], 2) );
            s.mutants = mm.listM;
            s.posFig = [100 100 900 1100];
            s.typePlot = 'bar';
            s.sizeMarker = 6;
            s.widthLine = 4;
            s.widthErrorbar = 0.8;
            s.rotationXTick = 45;
            s.numYtick = 4;
            s.roundYtick = repmat(2, 1, s.sizeZ);
            s.flgZebra = false;
            
            mm.saveStats(s);
        end
%=================================================================================================================================
    function saveStats(mm, s)    
            nameVar = {'Raw', 'Mean', 'SD', 'SE', 'CI83', 'NumWorms'};
            cl = cell( s.sizeM * s.sizeP * s.sizeB, numel(nameVar) );
            stats = cell2table( cl, 'VariableName', nameVar);   
        
        
    end
%=================================================================================================================================
    function cl = extractCell(mm, stat, analysis, type)

            [M, P, B] = mm.getSizes;

            switch type
                case 't'
                    cl = cell(M, P);
                otherwise
                    cl = cell(M, P, B);
            end
            
            
            for m = 1:M
                for p = 1:P
                    switch type
                        case 't'
                            if isempty(stat)
                                cl{m, p} = mm.mutants(m).phases(p).(analysis);
                            else
                                cl{m, p} = mm.mutants(m).phases(p).(analysis).(stat);
                            end
                        case 'b'
                            flgC = iscell( mm.mutants(m).phases(p).(analysis).(stat) );
                            for b = 1:B
                                if flgC
                                    cl{m, p, b} = mm.mutants(m).phases(p).(analysis).(stat){b};
                                else
                                    cl{m, p, b} = mm.mutants(m).phases(p).(analysis).(stat)(b);
                                end
                            end
                    end
%                     for b = 1:B
%                         switch mm.type
%                             case 'transitions'
%                                 %                         if flgC
%                                 if isempty(stat)
%                                     cl{m, p, b} = mm.mutants(m).phases(p).(kind);
%                                 else
%                                     cl{m, p, b} = mm.mutants(m).phases(p).(kind).(stat);
%                                 end
%                             case 't'
%                                 cl{m, p, b} = mm.mutants(m).phases(p).(kind).(stat)(b, 1);
%                             otherwise
% %                                 cl{m, p, b} = mm.mutants(m).phases(p).behaviors(b).(mm.type).(stat);
%                                 cl{m, p, b} = mm.mutants(m).phases(p).(kind).(stat){b};
%                         end
%                     end
                end
            end

        end
%=================================================================================================================================
        function mat = extractMatrix(mm, stat)
            
            [M, P, B] = mm.getSizes;

            switch mm.type
                case 'transitions'
                    error('Use extractCell for this data type.');
            end

            mat = nan(M, P, B);
            
            for b = 1:B
                for m = 1:M
                    for p = 1:P
                        mat(m, p, b) = mm.mutants(m).phases(p).(mm.type).(stat)(b);
                    end
                end
            end
        
        end
%=================================================================================================================================
        function [r, c] = adj2sub(m, adj)
            
            % Extract transitions by adjacency matrix
            aj = reshape(cat(3, adj{:}), m.nBehaviors, m.nBehaviors, m.nPhases, m.nMutants); % Convert cell/double matrix to double matrix (vectorized)
            aj = squeeze( all(aj, 3) );                      % Transitions that appear in all phases
            [r, c] = ind2sub( size( aj(:, :, 1) ), find( aj(:, :, 1) ) );
        end
%=================================================================================================================================
        function [m, p, b] = getSizes(mm)
            m = mm.nMutants;
            p = mm.nPhases;
            b = mm.nBehaviors;
        end
    end
    
end