function y = awfm_IntrinsicImaging(t, pulsnum, freq1, amp1, wait)
% [DEFAULTS]
% pulsnum, 2,
% freq1, 1,
% amp1, 1,
% wait,1,
% [END]

pulsnum = defcheck(pulsnum, 2); %number of pulses
freq1 = defcheck(freq1, 1);
amp1 = defcheck(amp1, 1);


rate = 1 / t(2);
empty = round(wait*rate);
downsamps1 = round((1 / freq1)*rate);
%Samples at which it stays up is the same as downsamples (duty cycle of 0.5)
y = [];

y = [y, repmat([zeros(1, downsamps1), amp1 + zeros(1, downsamps1)], 1, pulsnum), zeros(1, empty)];

y = [zeros(1, empty), y];


% Check the size is the correct noe
if numel(y) < numel(t)
    y = repmat(y, [1, floor(numel(t)/numel(y))]);
    y = [y, zeros(1, (numel(t) - numel(y)))];
end

if numel(y) > numel(t)
    y = y(1:numel(t));
end
