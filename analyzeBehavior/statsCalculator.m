classdef statsCalculator < dataAllocator
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        sc________________;
        dataPerWorm;
        dataAsIndependent;
        
        meanDataPerWorm;
        sumDataPerWorm;
        countOfBehaviorsPerWorm;
        
        sumTotal;

        countTotal;
        
        meanDataAsIndependent;
        meanDataAsIndependentAlt;
        
        SD;
        SE;
        CI83;
        CI95;
        CI99;
    end
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    methods
        function sc = statsCalculator(cm)
            sc = sc@dataAllocator(cm);                                  % Inherit all fields from cropped struct via dataAllocator
        end
%=================================================================================================================================
        function getStats(obj)
            
            if iscell(obj.dataPerWorm)
                obj.meanDataPerWorm = cellfun(@mean, obj.dataPerWorm);
                obj.sumDataPerWorm = cellfun(@sum, obj.dataPerWorm);
                obj.countOfBehaviorsPerWorm = cellfun(@(x) size(x, 2), obj.dataPerWorm);
                
                obj.sumTotal = sum(obj.sumDataPerWorm);
                obj.countTotal = sum(obj.countOfBehaviorsPerWorm);
                obj.meanDataAsIndependent = obj.sumTotal / obj.countTotal;
                obj.meanDataAsIndependentAlt = mean(obj.dataAsIndependent); % Shold be exactly same as meanDataAsIndependent
            else
                obj.dataAsIndependent = obj.dataPerWorm;
                obj.meanDataAsIndependent = mean(obj.dataAsIndependent);
                obj.countTotal = size(obj.dataPerWorm, 1);
            end

            obj.SD = std(obj.dataAsIndependent, 0);
            obj.SE = obj.SD ./ sqrt(obj.countTotal);
            obj.CI83 = obj.SE .* 1.386;                 % For 83.4% CI that would match P = 0.05
            obj.CI95 = obj.SE .* 1.96;
            obj.CI99 = obj.SE .* 2.58;
        end
%=================================================================================================================================
        function getHist(obj)
            
            
            
        end
    end

end

