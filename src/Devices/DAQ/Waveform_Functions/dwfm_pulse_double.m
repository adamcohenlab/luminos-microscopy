function y = dwfm_pulse_double(t, dltT, phase, duty, nPulses, dltT2, phase2, duty2, nPulses2)
% [DEFAULTS] add default values and units below
% dltT, 1
% phase, 0
% duty, 0.01
% nPulses
% dltT2, 1
% phase2, 0
% duty2, 0.01
% nPulses2
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


dltT2 = defcheck(dltT2, 1);
phase2 = defcheck(phase2, 0);
duty2 = defcheck(duty2, 0.01);
nPulses2 = defcheck(nPulses2, int32(floor((max(t) + t(2))/dltT2)));
rate2 = 1 / t(2);
pulseSamps2 = round(dltT2*duty2*rate2);
blankSamps2 = round(dltT2*rate2) - pulseSamps2;
y2 = [];
for i = 1:nPulses2
    y2 = [y2, (zeros(1, blankSamps2)), ...
        (ones(1, pulseSamps2))];
end
y2 = circshift(y, round(dltT2*rate2*phase2));
if numel(y2) < numel(t)
    %     y=repmat(y,[1 floor(numel(t)/numel(y))]);
    y2 = [y2, zeros(1, (numel(t) - numel(y2)))];
end
if numel(y2) > numel(t)
    y2 = y2(1:numel(t));
end
y2(end) = 0;


y = min(y + y2, 1);

end
