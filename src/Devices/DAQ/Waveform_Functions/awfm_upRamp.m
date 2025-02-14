function y = awfm_upRamp(t, rest_time, ramp_time, minval, maxval)
% [DEFAULTS]
% rest_time, 0.5, s
% ramp_time, 0.5, s
% minval, 0, V
% maxval, 1, V
% [END]
% a single linear increasing ramp
rest_time = defcheck(rest_time, .5); % steady-state time, automatically added to the beginning and end of the waveform; sec
ramp_time = defcheck(ramp_time, .5); % ramp time, sec
rest_samps = round(rest_time*1/t(2));
ramp_samps = round(ramp_time*1/t(2));
minval = defcheck(minval, 0); % the minimal value, V
maxval = defcheck(maxval, 1); % the maximal value, V
y = zeros(1, rest_samps+ramp_samps) + minval;
y(1:ramp_samps) = linspace(minval, maxval, ramp_samps);
y = tile_and_pad(y, t, minval);
end
