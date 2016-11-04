classdef correlationManager < abstractManager
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    properties
        bm;
        nm;
        corrDerivative;
        corrRatio;
        correlations;
        neurons;
        behaviors;
        numBehaviors;
        numNeurons;
        
        flgLimitCorrRange = true;
        corrTimeMin = 45;
        corrTimeMax = 70;
        idxNonNan;
        corrSignNeuron;
        corrSignBehavior;

    end
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods
        function cm = correlationManager()
            cm = cm@abstractManager();

        end
%=================================================================================================================================
        function getManagers(cm, pathNM, pathBM)

            s = load([pathNM, '\neuronManager.mat']);
            cm.nm = s.nm;
            cm.neurons = s.nm.neurons;
            cm.neurons.nameStrain = s.nm.nameStrain;
            
            s = load([pathBM, '\behaviorManager.mat']);
            cm.bm = s.bm;
            cm.behaviors = s.bm.behaviors;
            cm.behaviors.probabilities = s.bm.probabilities;
            cm.behaviors.timepoints = s.bm.timepoints;
            cm.behaviors.nameStrain = s.bm.nameStrain;            
            
        end
%=================================================================================================================================        
        function manageXcorrs(cm)
            
            cm.corrRatio = cm.getXcorr(cm.behaviors.TS{1}.Time, cm.behaviors.probabilities, cm.neurons.stats.Mean);
            cm.corrDerivative = cm.getXcorr(cm.behaviors.TS{1}.Time, cm.behaviors.probabilities, cm.neurons.stats.Derivative);

        end
%=================================================================================================================================
        function corr = getXcorr(cm, tim, beh, neu)

            cl = cell(cm.numNeurons, cm.numBehaviors + 1);

            corr = cell2table( cl, 'VariableName', [cm.behaviors.list', 'Time'], 'RowNames', cm.neurons.names);
            
            T = tim;

            for bp = 1:cm.numBehaviors

                B = beh(:, bp);

                for nr = 1:cm.numNeurons

                    N = neu{nr};
                    if cm.flgLimitCorrRange
                        nn = T >= cm.corrTimeMin & T < cm.corrTimeMax;
                    else
                        nn = all(~isnan( ([T, B, N]) ),2);                      % Index of non-nan elements for all the vectors
                    end
                    BNN = B(nn);
                    NNN = N(nn);
                    TNN = T(nn);
                    if bp == 1
                        corr{nr, 5} = {TNN};
                    end
                    
                    L = TNN - min(TNN);

                    LG = [-1 .* flipud(L); L(2:end)];                           % Construct lag array
                    r = xcorr(BNN-mean(BNN), NNN-mean(NNN), 'coeff');
                    R = nan( size(LG) );
                    R(LG < 10 & LG > -10) = r(LG < 10 & LG > -10);
                    
                    if bp == 1
                        ANT = TNN < cm.corrTimeMin + 5;
                        cm.corrSignNeuron(nr, 1) = mean( NNN(ANT) ) < mean( NNN(~ANT) );
                    end
                    if nr == 1
                        ANT = TNN < cm.corrTimeMin + 5;
                        cm.corrSignBehavior(bp, 1) = mean( BNN(ANT) ) < mean( BNN(~ANT) );
                    end

                    if xor( cm.corrSignNeuron(nr), cm.corrSignBehavior(bp) )    % if directions are not the same
                        [X{nr}.maxR, ix] = min(R);                              % corr sign is negative
                    else                                                        % if directions are the same
                        [X{nr}.maxR, ix] = max(R);                              % corr sign is positive
                    end
                    X{nr}.maxLag = LG(ix);
                    X{nr}.r = r;
                    X{nr}.lags = LG;
                end
                corr{:, bp} = X';
                
            end
            cm.idxNonNan = nn;

        end
%=================================================================================================================================
        function setParameters(cm, flg, min, max)
            cm.flgLimitCorrRange = flg;
            cm.corrTimeMin = min;
            cm.corrTimeMax = max;
        end
%=================================================================================================================================
        function preparePlots(cm)
            
            cm.numBehaviors = size(cm.behaviors.probabilities, 2);
            cm.numNeurons = size(cm.neurons.stats, 1);

        end
        
    end
    
end

