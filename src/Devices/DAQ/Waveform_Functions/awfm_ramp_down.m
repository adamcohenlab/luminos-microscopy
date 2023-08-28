function y = awfm_ramp_down(t, rest_time, ramp_time, minval, maxval)
% a single linear increasing ramp


% [DEFAULTS] add default values and units below
% rest_time, 0.5, s
% ramp_time, 0.5, s
% minval, 0, V
% maxval, 1, v
% [END]

rest_samps = round(rest_time*1/t(2));
ramp_samps = round(ramp_time*1/t(2));
y = zeros(1, rest_samps+ramp_samps) + minval;
y(round(rest_samps/2)+1:round(rest_samps/2)+ramp_samps) = linspace(maxval, minval, ramp_samps);
y = tile_and_pad(y, t, minval);
end
