function pubBehaviors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% File Handling

% pathInput = 'E:\dataTemp';

pathInput = '\\DS213\data\Ippei\Publication\Behaviors';
listFilesLen = rdir([pathInput, '\*\lenBehav*.mat']);              % Get a list of lenBehav.mat files in the subfolders
listFilesBeh = rdir([pathInput, '\*\behaviorManager.mat']);    % Get a list of BehaviorsResampled.mat files in the subfolders
numFiles = numel(listFilesBeh);
if numFiles < 1
    prt('No worm to plot.');
    return
end
for nf = 1:numFiles
    df(nf, 1) = dataFormatter(listFilesBeh(nf).name);
end
 
l = lengthCalculator.empty;
o = onsetCalculator.empty;
d = durationCalculator.empty;
t = transitionCalculator.empty;
f = fractionCalculator.empty;

flgLen = 0;
flgOnset = 0;
flgTrans = 1;
flgFrac = 1;

order = 'pmb';
ranges = {'[1, 2:1:end]', '1:end', '1:end'};
type = 'boot';
typeLimit = 'narrow';
flgRawData = false;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Lengths of Behaviors

if flgLen
    m = mutantManager(df, 'lengths');
    g = graphicManager(m);
    
%     s = m.preparePlotData('lengths', 'mpb', {'1:end', '[1, 2:2:end]', '1:end'}, false);
%     g.plotHistograms(s, 'Histogram of Behavior Lengths');

    s = m.preparePlotData('lengths', order, ranges, false);
    g.plotND(s, 'Behavior Lengths');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Onset of the First Behavior
 
if flgOnset
    m = mutantManager(df, 'onsets');
    g = graphicManager(m);
%     s = m.preparePlotData('onsets', 'mpb', {'1:end', '[1, 2:2:end]', '1:end'}, false);
%     g.plotHistograms(s, 'Histogram of Onsets');
    s = m.preparePlotData('onsets', 'mpb', {'1:end', '[1, 2:1:end]', '1:end'}, false);
    g.plotND(s, 'Onset of the First Behaviors');
end

%% Transition Analysis

if flgTrans

    m = mutantManager(df, 'transitions');
    g = graphicManager( {m.mutants(1).phases(2, 1)} );
    
%     g.makeGraph;
    
%     % Fig. 4D
    order = 'pmb';
    ranges = {'[2:2:end]', '1:end', '3'};
    s = m.preparePlotData('ratesTransition', order, ranges, false);
    s.typePlot = type;
    s.posFig = [100 100 1000 260];
    s.rotationXTick = 0;
    s.widthErrorbar = 0.2;
    s.widthLine = [];
    s.sizeMarker = 9;
    s.flgRawData = flgRawData;
    switch typeLimit
        case 'narrow'
            s.maxData = [0.3, 0.3, 0.3, 0.4];
            s.minData = [0.05, 0.05, 0.05, 0];            
        case 'wide'
            s.maxData = [1.5, 0.1, 0.4, 0.4];
            s.minData = [0, 0.01, 0, 0];
    end
    g.plotND(s);
    g.saveStats(pathInput, 'Fig4D_stats.mat');
    
    % Sup. Fig. 4 fs2
    order = 'pmb';
    ranges = {'1:end', '1:end', '1:end'};
    s = m.preparePlotData('ratesTransition', order, ranges, false);
    s.typePlot = type;
    s.posFig = [100 100 1000 800];
    s.rotationXTick = 0;
    s.widthErrorbar = 0.25;
    s.widthLine = [];
    s.sizeMarker = 9;
    s.flgZebra = false;
    s.flgRawData = flgRawData;
    switch typeLimit
        case 'narrow'
            s.maxData = [0.6, 0.9, 0.3, 0.7];
            s.minData = [0.1, 0.2, 0, 0];
        case 'wide'
            s.maxData = [1.8, 1.5, 1.5, 1.5];
            s.minData = [0, 0, 0, 0];
    end
    g.plotND(s);
    g.saveStats(pathInput, 'Fig4_fs2_stats.mat');
    
    
    cl = m.extractCell('data', 'ratesTransition', 't');
    cl = cat(3, cl{:, 2});
    for x = 1:3
        for y = 1:3
            
            v = squeeze(cl(x, y, :));
            if all(~cellfun(@isempty, v))
                st(x, y) = ntests(v);
            end
        end
    end
       
%     categ = {'all', 'heat'};
%     stateTransitions(categ);
%     s = m.preparePlotData('totalTransition', order, ranges, false);
%     g.plotND(s, 'Transition Total');
%     s = m.preparePlotData('lengthsTransition', order, ranges, false);
%     g.plotND(s, 'Transition Lengths');
%     s = m.preparePlotData('ratesTransition', order, ranges, false);
%     g.plotND(s, 'Transition Rates');
%     s = m.preparePlotData('lengthsExit', order, ranges, false);
%     g.plotND(s, 'Exit Lengths');
%     
%     s = m.preparePlotData('ratesExit', order, ranges, false);
%     g.plotND(s, 'Exit Rates');
%     
%     s = m.preparePlotData('countsTransition', order, ranges, false);
%     g.plotND(s, 'Transition Counts');
%     
%     s = m.preparePlotData('countsExit', order, ranges, false);
%     g.plotND(s, 'Exit Counts');
%     
%     s = m.preparePlotData('lengthsPrevious', order, ranges, false);
%     g.plotND(s, 'Previous Lengths');
%     
%     s = m.preparePlotData('ratePrevious', order, ranges, false);
%     g.plotND(s, 'Previous Rates');
%     g.imageBehaviors;
%     s = m.preparePlotData('ratesTransition', 'mpb', {'1:end', '[1, 2:2:end]', '1:end'}, false);
%     g.plotHistograms(s, 'Histogram of Transition Rates');
  
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Fractions of Behaviors



if flgFrac
    
    % Fig. 4A
    order = 'mpb';
    ranges = {'1:end', '2', '1:3'};    
    m = mutantManager(df, 'fractions');
    g = graphicManager(m);
    s = m.preparePlotData('fractions', order, ranges, false);
    s.minData = [0, 0, 0, 0];
    s.posFig = [100 100 260 800];
    s.typePlot = type;
    s.titles = [];
    s.colors = repmat({[0.8 0.5 0.5]}, 1, 3);
    s.markers = repmat({'o'}, 1, 5);
    s.widthLine = [];
    s.sizeMarker = 9;
    s.widthErrorbar = 0.25;
    s.flgRawData = flgRawData;
    switch typeLimit
        case 'narrow'
            s.maxData = [0.68, 0.32, 0.1, 0.4];
            s.minData = [0.58, 0.22, 0, 0];
        case 'wide'
            s.maxData = [1, 1, 0.3, 0.4];
            s.minData = [0, 0, 0, 0];
    end
    g.plotND(s);
    g.saveStats(pathInput, 'Fig4A_stats.mat');
    
    
%     cl = m.extractCell('data', 'fractions', 'b');
%     cl = squeeze(cl(:, 2, :));
%     
%     for b = 1:3
%         st(b) = ntests(cl(:,b));
%     end
    
%     g.objAnalysis.mutants
    
%     
%     Sup. Fig. 4 fs1
    order = 'pmb';
    ranges = {'[1, 2:1:end]', '1:end', '1:3'};
    m = mutantManager(df, 'fractions');
    g = graphicManager(m);
    s = m.preparePlotData('fractions', order, ranges, false);
    s.typePlot = type;
    s.posFig = [100 100 1000 800];
    s.widthLine = [];
    s.sizeMarker = 9;
    s.widthErrorbar = 0.25;
%     s.xtick = {'P', 'H1', 'L1', 'H2', 'L2', 'H3', 'L3', 'H4', 'L4', 'H5', 'L5'};
    s.rotationXTick = 0;
    s.roundYtick = [2 2 2 2];
    s.flgZebra = false;
    s.flgRawData = flgRawData;
    switch typeLimit
        case 'narrow'
            s.maxData = [1, 0.35, 0.1, 0.4];
            s.minData = [0.5, 0, 0, 0];
        case 'wide'
            s.maxData = [1, 0.8, 0.3, 0.1];
            s.minData = [0, 0, 0, 0];
    end
    g.plotND(s);
    g.saveStats(pathInput, 'Fig4_fs1_stats.mat');

    % Fig. 4BC
    order = 'pmb';
    ranges = {'[2:2:end]', '1:end', '2:3'};
    m = mutantManager(df, 'fractions');
    g = graphicManager(m);
    s = m.preparePlotData('fractions', order, ranges, false);
    s.typePlot = type;
    s.posFig = [100 100 1000 600];
    s.widthLine = [];
    s.sizeMarker = 9;
%     s.xtick = {'P', 'H1', 'L1', 'H2', 'L2', 'H3', 'L3', 'H4', 'L4', 'H5', 'L5'};
    s.rotationXTick = 0;
    s.widthErrorbar = 0.25;
    s.flgRawData = flgRawData;
    switch typeLimit
        case 'narrow'
            s.maxData = [0.33, 0.1, 0.4, 0.4];
            s.minData = [0.15, 0.01, 0, 0];
        case 'wide'
            s.maxData = [0.8, 0.3, 0.4, 0.4];
            s.minData = [0, 0, 0, 0];
    end
    g.plotND(s);
    g.saveStats(pathInput, 'Fig4BC_stats.mat');
    
end

% close all;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Nested Functions

    function stateTransitions(c)
        t = arrayfun(@(x) transitionCalculator(x, c, false, false), df, 'Un', false); % Instantiate transitionCalculator objects
        cellfun(@(x) x.getAllTransitions, t, 'Un', 0);
        gm = graphicManager(t);
        gm.makeGraph;
    end
%=================================================================================================================================
    function meanLengths(c)
        l = arrayfun(@(x) lengthCalculator(x, c, false, false), df, 'Un', false);     % Instantiate lengthCalculator objects
        gm = graphicManager(l);
        gm.plotHistograms;
        gm.plotStatsAmongMutants;
    end
%=================================================================================================================================
    function fractionBehaviors(c)
        f = arrayfun(@(x) fractionCalculator(x, c), df, 'Un', false);                 % Instantiate fractionCalculator objects
        gm = graphicManager(f);
        gm.plotFractions;

    end
%=================================================================================================================================
    function meanOnset(c)
        flgIgnoreFirst = true;
        o = arrayfun(@(x) onsetCalculator(x, c, flgIgnoreFirst), df, 'Un', false);      % Instantiate onsetCalculator objects
        gm = graphicManager(o);
        gm.plotOnsets;
    end
%=================================================================================================================================
    function meanDuration(c)
        d = arrayfun(@(x) durationCalculator(x, c), df, 'Un', false);                % Instantiate durationCalculator objects
        gm = graphicManager(d);
        gm.plotHistograms;
        gm.plotStatsAmongMutants;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end
%#ok<*AGROW>
