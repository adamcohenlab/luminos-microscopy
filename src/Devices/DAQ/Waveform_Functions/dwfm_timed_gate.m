function y = dwfm_timed_gate(t, pre_time, post_time)
% [DEFAULTS] add default values and units below
% pre_time, 0.1, s
% post_time, 0, s
% [END]
rate = 1 / (t(2));
y = zeros(1, numel(t));
y(round(pre_time*rate):(numel(t) - post_time * rate)) = 1;
y(end) = 0;
end
