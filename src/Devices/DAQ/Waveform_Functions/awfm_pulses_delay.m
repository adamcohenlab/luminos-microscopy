function y = awfm_pulses_delay(t, low_v, high_v, dlta, up_t, down_t, nstps, delay, repeat)
% [DEFAULTS] add default values and units below
% low_v, 0, V
% high_v, 1, V
% dlta, 0.1
% up_t, 0.1, s
% down_t, 0.1, s
% nstps, 5
% delay, 0, s
% repeat, 0
% [END]

low_v = defcheck(low_v, 0);
high_v = defcheck(high_v, 1);
dlta = defcheck(dlta, .1);
up_t = defcheck(up_t, .1);
down_t = defcheck(down_t, .1);
nstps = defcheck(nstps, 5);
delay = defcheck(delay, 0);
repeat = defcheck(repeat, 0);

rate = 1 / t(2);
downsamps = round(down_t*rate);
upsamps = round(up_t*rate);

y = [];
if round(delay*rate) > 0
    y(round(delay*rate)) = low_v;
end
for i = 1:nstps
    y = [y, (low_v + zeros(1, downsamps)), ...
        ((high_v + (i - 1) * dlta) + zeros(1, upsamps))];
end
%y=circshift(y,floor((upsamps+downsamps)*phase));
if numel(y) < numel(t)
    if repeat
        y = repmat(y, [1, floor(numel(t)/numel(y))]);
    end
    y = [y, zeros(1, (numel(t) - numel(y))) + low_v];
end
if numel(y) > numel(t)
    y = y(1:numel(t));
end
y(end) = low_v;
end
