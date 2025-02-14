function y = awfm_single_pulse_manual(t, time_duration, amplitude, time_before, time_after)
% [DEFAULTS] add default values and units below
% time_duration
% amplitude
% time_before
% time_after
% [END]
rate = 1 / t(2);
empty = round(1*rate);

upsamps = round(time_duration*rate);
y = [];

y = [[amplitude + zeros(1, upsamps)], zeros(1, empty*time_after)];

y = [zeros(1, empty*time_before), y];


% Check the size is the correct noe
if numel(y) < numel(t)
    y = repmat(y, [1, floor(numel(t)/numel(y))]);
    y = [y, zeros(1, (numel(t) - numel(y)))];
end

if numel(y) > numel(t)
    y = y(1:numel(t));
end
