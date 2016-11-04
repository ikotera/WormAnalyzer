function [amplitude, time] = parseZapPlan(plan, power, durationPlan, durationZap)

rateSampling = 50;
cnt = 1;
durationPlan = durationPlan * rateSampling;
durationZap  = durationZap * rateSampling;
plan = plan * rateSampling;

amplitude = nan(durationPlan, 1);
time = nan(durationPlan, 1);

for t = 1:durationPlan
    if t >= plan(cnt) &&... % after laser 'on'
       t <= plan(cnt) + durationZap / 1000 % before laser 'off'
        amplitude(t, 1) = power;
    else
        amplitude(t, 1) = 0;
    end

    if t > plan(cnt) + durationZap / 1000 &&... % after laser 'off'
            cnt < numel(plan) % before completion of laser plan
        cnt = cnt + 1;
    end
    
    time(t, 1) = t / rateSampling;
end

end