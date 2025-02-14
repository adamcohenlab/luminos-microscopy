function y = awfm_pulses(t, low_v, high_v, dlta, up_t, down_t, nstps, load_cal, phase)

% [DEFAULTS] add default values and units below
% low_v, 0, V
% high_v, 1, V
% dlta, 0.1
% up_t, , s
% down_t, , s
% nstps, 5
% load_cal, -1
% phase, 0
% [END]

low_v = defcheck(low_v, 0);
high_v = defcheck(high_v, 1);
dlta = defcheck(dlta, .1);
up_t = defcheck(up_t, .1);
down_t = defcheck(down_t, .1);
phase = defcheck(phase, 0);
nstps = defcheck(nstps, 5);
load_cal = defcheck(load_cal, -1);

rate = 1 / t(2);
downsamps = round(down_t*rate);
upsamps = round(up_t*rate);
y = [];
for i = 1:nstps
    y = [y, (low_v + zeros(1, downsamps)), ...
        ((high_v + (i - 1) * dlta) + zeros(1, upsamps))];
end
y = circshift(y, floor((upsamps + downsamps)*phase));
if numel(y) < numel(t)
    y = repmat(y, [1, floor(numel(t)/numel(y))]);
    y = [y, zeros(1, (numel(t) - numel(y))) + low_v];
end
if numel(y) > numel(t)
    y = y(1:numel(t));
end
y(end) = low_v;

if load_cal == 1
    cal = load("Adaptive_Upright_calibration\AU_AOTF_Cal_Out_Inverse.mat");
    y = feval(cal.fit, y)';
    y(y == min(y)) = 0;
elseif load_cal == 2
    cal = load("Adaptive_Upright_calibration\AU_EOM_Inverse.mat");
    y = feval(cal.fit, y)';
    y(y == min(y)) = 0;
elseif load_cal == 3
    cal = load("Adaptive_Upright_calibration\AU_637_Cal_Out_Inverse.mat");
    y = feval(cal.fit, y)';
    y(y == min(y)) = 0;
elseif load_cal == 4
    cal = load("Adaptive_Upright_calibration\AU_637_OD1_Cal_Out_Inverse.mat");
    y = feval(cal.fit, y)';
    y(y == min(y)) = 0;
elseif load_cal == 5
    cal = load("Adaptive_Upright_calibration\DS_850_Cal_Out_Inverse.mat");
    y = feval(cal.fit, y)';
    y(y == min(y)) = 0;
elseif load_cal == 6
    cal = load("Adaptive_Upright_calibration\DS_1220_Cal_Out_Inverse.mat");
    y = feval(cal.fit, y)';
    y(y == min(y)) = 0;
elseif load_cal == 7
    cal = load("Adaptive_Upright_calibration\AOTF_532_Cal_Out_Inverse.mat");
    y = feval(cal.fit, y)';
    y(y == min(y)) = 0;
end
end
