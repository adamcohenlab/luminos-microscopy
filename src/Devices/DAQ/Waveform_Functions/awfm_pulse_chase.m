function y = awfm_pulse_chase(t, low_v, high_v1, high_v2, width1, width2, T1, T2, nstps, delay, repeat)
% [DEFAULTS] add default values and units below
% low_v, 0
% high_v1, 1
% high_v2, 1
% width1, 0.1, s
% width2, 0.1, s
% T1, 1, s
% T2, 1.1, s
% nstps, 5
% delay, 0, s
% repeat, 1
% [END]
low_v = defcheck(low_v, 0);
high_v1 = defcheck(high_v1, 1);
high_v2 = defcheck(high_v2, 1);
width1 = defcheck(width1, 0.1);
width2 = defcheck(width2, 0.1);
T1 = defcheck(T1, 1);
T2 = defcheck(T2, 1.1);
nstps = defcheck(nstps, 5);
delay = defcheck(delay, 0);
repeat = defcheck(repeat, 1);

rate = 1 / t(2);
upsamps1 = round(width1*rate);
upsamps2 = round(width2*rate);
downsamps1 = round(T1*rate-upsamps1);
downsamps2 = round(T2*rate-upsamps2);

y1 = [];
y2 = [];
if round(delay*rate) > 0
    y1(round(delay*rate)) = low_v;
    y2(round(delay*rate)) = low_v;
end
for i = 1:nstps
    y1 = [y1, (low_v + zeros(1, downsamps1)), ...
        (high_v1 + +zeros(1, upsamps1))];
    y2 = [y2, (low_v + zeros(1, downsamps2)), ...
        (high_v2 + +zeros(1, upsamps2))];
end
if numel(y1) < numel(y2)
    y1(end+1:numel(y2)) = low_v;
elseif numel(y2) < numel(y1)
    y2(end+1:numel(y1)) = low_v;
end
y = max(y1, y2);
if numel(y) < numel(t)
    if repeat
        y = repmat(y, [1, floor(numel(t)/numel(y))]);
    end
    y = [y, zeros(1, (numel(t) - numel(y))) + low_v];
end
if numel(y) > numel(t)
    y = y(1:numel(t));
end
y(end) = 0;
end


function y = defcheck(x, default)
if x == -Inf
    y = default;
else
    y = x;
end
end