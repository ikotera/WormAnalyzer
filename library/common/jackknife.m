function SD = jackknife(sample)

n = length(sample);
H = nan(1, n); % Preallocation

% jackknifing
for ix = 1:n
    sp = sample;
    sp(ix) = [];
    H(ix) = (n - 1) / sum(1./sp);
end

% jackknife variance
V = ((n-1)/n) * sum((H - mean(H)).^2); % Eq 12

% SD value
SD = sqrt(V * n);

end