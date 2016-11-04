classdef statManager < handle
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    properties
        data;
        sum;
        count;
        mean;
        median;
        SD;
        SE;
        CI83;
        CI95;
        CI99;
        P75;
        P25;
        bootL;
        bootH;
        flgHarmonic;
        type;
        
    end
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    methods
        function sm = statManager(data, flgHarmonic, type)
            sm.flgHarmonic = flgHarmonic;
            sm.type = type;
            
            if iscell(data)
                if flgHarmonic
                    sm.mean = cellfun(@harmmean, data);
                    sm.SD = cellfun(@(x) jackknife(x), data);
                else
                    sm.mean = cellfun(@mean, data);
                    sm.SD = cellfun(@(x) std(x), data);
                end
                sm.sum = cellfun(@sum, data);
                sm.count = cellfun(@(x) numel(x), data);
                sm.median = cellfun(@median, data);
                sm.P25 = cellfun(@(x) median(x) - prctile(x, 40), data);
                sm.P75 = cellfun(@(x) prctile(x, 60) - median(x), data);
%                 ci = cellfun(@(x) bootci(1000, @mean, x), data);
                
                sm.bootL = zeros(size(data)); sm.bootH = zeros(size(data));
                for y = 1:size(data, 1)
                    for x = 1:size(data, 2)
                        if ~isempty(data{y, x}) && numel(data{y, x}) > 1
                            ci = bootci(1000, {@mean, data{y, x}}, 'type','cper', 'alpha', 0.166);
                            sm.bootL(y, x) = mean(data{y, x}) - ci(1);
                            sm.bootH(y, x) = ci(2) - mean(data{y, x});
                        end
                    end
                end
                
            else
                if flgHarmonic
                    sm.mean = harmmean(data, 1);
                    sm.SD = jackknife(data);
                else
                    sm.mean = mean(data, 1);
                    sm.SD = std(data, 0, 1);
                end
                sm.sum = sum(data, 1);
                sm.count = size(data, 1);
                sm.median = median(data, 1);
                sm.P25 = sm.median - prctile(data, 40);
                sm.P75 = prctile(data, 60) - sm.median;
                
            end

            sm.data = data;
            sm.SE = sm.SD ./ sqrt(sm.count);
            sm.CI83 = sm.SE .* 1.386;                 % For 83.4% CI that would match P = 0.05
            sm.CI95 = sm.SE .* 1.96;
            sm.CI99 = sm.SE .* 2.58;

            
            if isempty(sm.data)
                sm.data = nan;
                sm.mean = nan;
                sm.count = nan;
                sm.sum = nan;
            end
        end
    end
    
end
