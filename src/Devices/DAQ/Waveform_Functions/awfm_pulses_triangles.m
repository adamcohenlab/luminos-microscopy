function outdata = awfm_pulses_triangles(t, ss_v, rest_t, rmphght, rampt, nramps, stp_upt, stp_dwnt, nstps, frststp_hght, stpdlta)
% [DEFAULTS] add default values and units below
% ss_v, 0, V
% rest_t, , s
% rmphght, 1, V
% rampt, , s
% nramps, 1,
% stp_upt, , s
% stp_dwnt, stp_upt, s
% nstps, 3,
% frststp_hght, 0.5, V
% stpdlta, 0.25,
% [END]

ss_voltage = defcheck(ss_v, 0); %steady-state voltage, V
rest_t = defcheck(rest_t, .1*(t(end) + t(2))); % steady-state time, automatically added to the beginning and end of the waveform; sec
rmphght = defcheck(rmphght, 1); % the height point of the ramp
rampt = defcheck(rampt, .3*(t(end) + t(2))); % ramp time, sec
nramps = defcheck(nramps, 1);
stp_upt = defcheck(stp_upt, .1*(t(end) + t(2))); % step up-time, sec
stp_dwnt = defcheck(stp_dwnt, stp_upt); %step down-time, sec
nstps = defcheck(nstps, 3); % number of step
frststp_hght = defcheck(frststp_hght, .5); %first step-height, V
stpdlta = defcheck(stpdlta, .25); % incremental increase as a fraction of the first step

rate = 1 / t(2);
rampsamps = round(rate*rampt);
upsamps = round(rate*stp_upt);
downsamps = round(rate*stp_dwnt);
restsamps = round(rate*rest_t);
rest_period = zeros(1, floor(restsamps/2)) + ss_voltage;
ramps_period = [];
for i = 1:nramps
    ramps_period = [ramps_period, linspace(ss_voltage, rmphght, floor(rampsamps/2)), linspace(rmphght, ss_voltage, ceil(rampsamps/2))];
end
steps_period = [];
for i = 1:nstps
    steps_period = [steps_period, (ss_voltage + zeros(1, downsamps)), ...
        ((frststp_hght + (i - 1) * stpdlta) + zeros(1, upsamps))];
end
outdata = [rest_period, steps_period, rest_period, ramps_period, rest_period];
if numel(outdata) < numel(t)
    outdata = repmat(outdata, [1, floor(numel(t)/numel(outdata))]);
    outdata = [outdata, zeros(1, (numel(t) - numel(outdata))) + ss_voltage];
end
if numel(outdata) > numel(t)
    outdata = outdata(1:numel(t));
end
outdata(end) = ss_voltage; %force final voltage to steady state level
end
