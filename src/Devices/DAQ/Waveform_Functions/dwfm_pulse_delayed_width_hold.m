function y = dwfm_pulse_delayed_width_hold(t, delay, dltT, phase, width, nPulses, wait, hold)
% [DEFAULTS] add default values and units below
% delay
% dltT, 1
% phase, 0
% width, 0.05
% nPulses
% wait
%  hold
% [END]
dltT = defcheck(dltT, 1);
phase = defcheck(phase, 0);
width = defcheck(width, 0.05);
nPulses = defcheck(nPulses, int32(floor((max(t) + t(2) - delay)/dltT)));
rate = 1 / t(2);
pulseSamps = round(width*rate);
blankSamps = round(dltT*rate) - pulseSamps;
y = zeros(1, int32(rate*delay));
for i = 1:nPulses
    y = [y, (ones(1, pulseSamps)), ...
        (zeros(1, blankSamps))];
end
y = circshift(y, round(dltT*rate*phase));

waitSamps = round(wait*rate);
holdSamps = round(hold*rate);
y = [y, zeros(1, waitSamps), ones(1, holdSamps)];

if numel(y) < numel(t)
    %     y=repmat(y,[1 floor(numel(t)/numel(y))]);
    y = [y, zeros(1, (numel(t) - numel(y)))];
end
if numel(y) > numel(t)
    y = y(1:numel(t));
end
y(end) = 0;
end
