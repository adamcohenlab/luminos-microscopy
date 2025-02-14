function y = dwfm_pulse_inverted(t, dltT, phase, duty, nPulses)
% [DEFAULTS] add default values and units below
% dltT, 1
% phase, 0
% duty, 0.01
% nPulses
% [END]
dltT = defcheck(dltT, 1);
phase = defcheck(phase, 0);
duty = defcheck(duty, 0.01);
nPulses = defcheck(nPulses, int32(floor((max(t) + t(2))/dltT)));
rate = 1 / t(2);
pulseSamps = round(dltT*duty*rate);
blankSamps = round(dltT*rate) - pulseSamps;
y = [];
for i = 1:nPulses
    y = [y, (zeros(1, blankSamps)), ...
        (ones(1, pulseSamps))];
end
y = circshift(y, round(dltT*rate*phase));
if numel(y) < numel(t)
    %     y=repmat(y,[1 floor(numel(t)/numel(y))]);
    y = [y, zeros(1, (numel(t) - numel(y)))];
end
if numel(y) > numel(t)
    y = y(1:numel(t));
end
y(end) = 0;
y = abs(y-1);
end
