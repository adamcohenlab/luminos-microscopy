function y = awfm_simple_pulses(t, high_v, on_time, off_time)

% [DEFAULTS] add default values and units below
% high_v, 1, V
% on_time, 1, s
% off_time, 1, s
% [END]
y = zeros(size(t));
for i = 1:length(t)
    if mod(t(i), on_time+off_time) < on_time
        y(i) = high_v;
    end
end
end