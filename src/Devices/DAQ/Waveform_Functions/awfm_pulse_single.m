function y = awfm_pulses_single(t, high_v, delay, pulse_duration)

% [DEFAULTS] add default values and units below
% high_v, 1, V
% delay, 0, s
% pulse_duration, 1, s
% [END]

y = zeros(size(t));
y(t > delay & t < (delay + pulse_duration)) = high_v;

end
