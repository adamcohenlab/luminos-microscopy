function y = dwfm_timed_gate(t, pre_time, post_time)
% [DEFAULTS] add default values and units below
% pre_time,,s
% post_time, 0,s
% [END]
pre_time = defcheck(pre_time, (t(end) + t(2))/10);
post_time = defcheck(post_time, 0);
rate = 1 / (t(2));
y = zeros(1, numel(t));
y(round(pre_time*rate):(numel(t) - round(post_time * rate))) = 1;
y(end) = 0;
end
