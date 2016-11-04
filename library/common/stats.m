function s = stats(sample)

    if ~isvector(sample)
        error('The input must be a vector');
    end
    if ~iscolumn(sample)
        sample = sample';
    end

    s.sample = sample;
    s.n = length(sample);
    s.mean = mean(sample, 1);
    s.SD = std(sample, 0, 1);
    s.SE = s.SD ./ sqrt(s.n);
    s.CI83 = s.SE .* 1.386;
    s.CI95 = s.SE .* 1.96;
    s.CI99 = s.SE .* 2.58;

end