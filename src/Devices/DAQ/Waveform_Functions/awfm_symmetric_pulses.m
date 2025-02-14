function y = awfm_symmetric_pulses(t, baseline_v, high_v, dlta, dlta_t, up_t, rest_t, nstps, phase)
% [DEFAULTS]
% baseline_v, 0
% high_v, 1
% dlta, .1
% dlta_t, 0
% up_t, .1
% rest_t, .1
% nstps, 5
% phase, 0
% [END]

baseline_v = defcheck(baseline_v, 0);
high_v = defcheck(high_v, 1);
dlta = defcheck(dlta, .1);
dlta_t = defcheck(dlta_t, 0);
up_t = defcheck(up_t, .1);
rest_t = defcheck(rest_t, .1);
phase = defcheck(phase, 0);
nstps = defcheck(nstps, 5);
rate = 1 / t(2);
restsamps = round(rest_t*rate);
%upsamps=round(up_t*rate);
y = [];
for i = 1:nstps
    y = [y, (baseline_v + zeros(1, restsamps)), ...
        ((high_v + (i - 1) * dlta) + zeros(1, round((up_t + (i - 1) * dlta_t)*rate))), ...
        (-(high_v + (i - 1) * dlta) + zeros(1, round((up_t + (i - 1) * dlta_t)*rate)))];
end
y = circshift(y, floor((2 * round((up_t + ((nstps - 1) / 2) * dlta_t)*rate) + restsamps)*phase));
if numel(y) < numel(t)
    y = repmat(y, [1, floor(numel(t)/numel(y))]);
    y = [y, zeros(1, (numel(t) - numel(y))) + baseline_v];
end
if numel(y) > numel(t)
    y = y(1:numel(t));
end
y(end) = baseline_v;

end
