function y = awfm_doubleRamp(t, rest_time, ramp_time, minval, maxval)
% a double linear symmetric ramp

% [DEFAULTS] add default values and units below
% rest_time, 0.5, s
% ramp_time, 0.5, s
% minval, 0, AO val
% maxval, 1, AO val
% [END]

rest_time = defcheck(rest_time, .5); % steady-state time, automatically added to the beginning and end of the waveform; sec
ramp_time = defcheck(ramp_time, .5); % ramp time, sec
rest_samps = round(rest_time*1/t(2));
ramp_samps = round(ramp_time*1/t(2));

minval = defcheck(minval, 0); % the minimal AO value
maxval = defcheck(maxval, 1); % the maximal AO value


y = zeros(1, rest_samps+ramp_samps) + minval;
y(round(rest_samps/2)+1:round(rest_samps/2)+round(ramp_samps/2)) = linspace(minval, maxval, round(ramp_samps/2));
y(round(rest_samps/2)+round(ramp_samps/2+1):round(rest_samps/2)+ramp_samps) = linspace(maxval, minval, round(ramp_samps/2));
y = tile_and_pad(y, t, minval);
end
