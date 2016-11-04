function s = ntests(V)

lenV = length(V);

            for c = 1:lenV
                for r = 1:lenV
                    
                    [f.h(r, c), f.p(r, c), f.ci{r, c}, f.stats(r, c)] =...
                        vartest2(V{c}, V{r});                               % Two-sample F-test for variance validity
                    if isnan(f.h(r, c))                                     % If F-test failed, likely missing behavior
                        t.h(r, c) = 0; t.p(r, c) = 1; t.ci{r, c} = nan; t.stats(r, c) = nan;
                    elseif ~f.h(r, c)                                       % If F-test is NOT rejected, ie, equal variance
                        [t.h(r, c), t.p(r, c), t.ci{r, c},  t.stats(r, c)] =...
                            ttest2(V{c}, V{r});                             % Two-sample t-test (equal variance)
                        t.var{r, c} = 'equal variance';
                    else
                        [t.h(r, c), t.p(r, c), t.ci{r, c},  t.stats(r, c)] =...
                            ttest2(V{c}, V{r}, 'Vartype', 'unequal');        % Two-sample t-test (unequal variance)
                        t.var{r, c} = 'unequal variance';
                    end
                    
                    t.harmmean{r, c} = [harmmean(V{r}), harmmean(V{c})];
                    t.mean{r, c} = [mean(V{r}), mean(V{c})];
                    t.data{r, c} = [V(r), V(c)];
                    t.sd{r, c} = [std(V{r}), std(V{c})];
%                     sm.SE = sm.SD ./ sqrt(sm.count);
%             sm.CI83 = sm.SE .* 1.386; 
                    
                    if t.p(r, c) <= 0.05 && t.p(r, c) > 1E-2
                        t.stars{r, c} = '*';
                    elseif t.p(r, c) <= 1E-2 && t.p(r, c) > 1E-3
                        t.stars{r, c}  = '**';
                    elseif t.p(r, c) <= 1E-3
                        t.stars{r, c}  = '***';
                    else
                        t.stars{r, c}  = '';    
                    end

                end
            end
            
            s.f = f;
            s.t = t;
            
end