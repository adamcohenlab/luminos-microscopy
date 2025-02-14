function y = awfm_downRamp(t, rest_time, ramp_time, minval, maxval)
% a single linear increasing ramp


% [DEFAULTS] add default values and units below
% rest_time, 0.5, s
% ramp_time, 0.5, s
% minval, 0, V
% maxval, 1, v
% [END]

rest_time = defcheck(rest_time, .5); % steady-state time, automatically added to the beginning and end of the waveform; sec
ramp_time = defcheck(ramp_time, .5); % ramp time, sec
rest_samps = round(rest_time*1/t(2));
ramp_samps = round(ramp_time*1/t(2));
minval = defcheck(minval, 0); % the minimal value, V
maxval = defcheck(maxval, 1); % the maximal value, V
y = zeros(1, rest_samps+ramp_samps) + minval;
y(round(rest_samps/2)+1:round(rest_samps/2)+ramp_samps) = linspace(maxval, minval, ramp_samps);
y = tile_and_pad(y, t, minval);
end
