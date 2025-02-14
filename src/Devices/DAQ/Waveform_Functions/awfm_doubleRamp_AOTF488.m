function outdata = awfm_doubleRamp_AOTF488(t, rest_time, ramp_time, minval, maxval)
% Take a V-response (e.g. AOTF output) calibration curve as the
% argument. The aim is to obtain linear output from a non-linear ramp
% curve_fit: the predetermined V-response fitting curve load as a cfit
% object

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

minval = defcheck(minval, 0); % the minimal AO value,must >0
maxval = defcheck(maxval, 1); % the maximal AO value, must <5
minval = max(minval, 0);
maxval = min(maxval, 5);

cali_data = load('C:\Updated_Control_Software\2020RigControl\src\Devices\DAQ\Waveform_Functions\Adaptive_Upright_calibration\oldcals\AU_AOTF.mat');
maxOutput = feval(cali_data.fit, maxval);
minOutput = feval(cali_data.fit, minval);
rampOutput = linspace(minOutput, maxOutput, ramp_samps);
rest_period = zeros(1, floor(rest_samps/2)) + minval;
ramp_values = arrayfun(@(y)fzero(@(x)cali_data.fit(x)-y, minval), linspace(minOutput, maxOutput, 1000));
ramp_period = interp1(linspace(minOutput, maxOutput, 1000), ramp_values, rampOutput);
outdata = [rest_period, ramp_period, flip(ramp_period), rest_period];
if numel(outdata) < numel(t)
    outdata = [outdata, zeros(1, (numel(t) - numel(outdata)))];
end
if numel(outdata) > numel(t)
    outdata = outdata(1:numel(t));
end
outdata(end) = 0;
end
