function y = dwfm_doublet_delayed(t, delay, dltT, tOn, phase, nPulses)
% [DEFAULTS]
% delay,
% dltT, 1
% tOn, 1
% phase, 0
% nPulses, 1
% [END]

rate = 1 / t(2);

pulseSamps = round(0.001*rate);
onSamps = round(tOn*rate);
blankSamps = round(dltT*rate) - pulseSamps - onSamps;

y = zeros(1, int32(rate*delay));
for i = 1:nPulses
    y = [y, (ones(1, pulseSamps)), (zeros(1, onSamps)), ...
        (ones(1, pulseSamps)), (zeros(1, blankSamps))];
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
end
