function y = awfm_pulses10sPatch(t, pulsnum, timss, freq1, amp1, freq2, amp2, freq3, amp3, freq4, amp4)
% [DEFAULTS] add default values and units below
% pulsnum, 2
% timss
% freq1, 1
% amp1, 1
% freq2, 1
% amp2, 1
% freq3, 1
% amp3, 1
% freq4, 1
% amp4, 1
% [END]
pulsnum = defcheck(pulsnum, 2); %number of pulses
freq1 = defcheck(freq1, 1);
amp1 = defcheck(amp1, 1);
freq2 = defcheck(freq2, 1);
amp2 = defcheck(amp2, 1);
freq3 = defcheck(freq3, 1);
amp3 = defcheck(amp3, 1);
freq4 = defcheck(freq4, 1);
amp4 = defcheck(amp4, 1);


rate = 1 / t(2);
empty = round(1*rate);
downsamps1 = round((1 / freq1)*rate);
downsamps2 = round((1 / freq2)*rate);
downsamps3 = round((1 / freq3)*rate);
downsamps4 = round((1 / freq4)*rate);
downsamps5 = round((1 / 200)*rate);
downsamps6 = round((1 / 90)*rate);
upsamps = round(timss*rate);
y = [];

y = [y, repmat([zeros(1, downsamps1), amp1 + zeros(1, upsamps)], 1, pulsnum), zeros(1, empty), ...
    repmat([zeros(1, downsamps2), amp2 + zeros(1, upsamps)], 1, pulsnum), zeros(1, empty), ...
    repmat([zeros(1, downsamps3), amp3 + zeros(1, upsamps)], 1, pulsnum), zeros(1, empty), ...
    repmat([zeros(1, downsamps4), amp4 + zeros(1, upsamps)], 1, pulsnum), zeros(1, empty), ...
    repmat([zeros(1, downsamps5), 5 + zeros(1, upsamps)], 1, pulsnum), zeros(1, empty), ...
    repmat([zeros(1, downsamps6), 5 + zeros(1, upsamps)], 1, pulsnum), zeros(1, empty), ...
    ];

y = [zeros(1, empty), y];


% Check the size is the correct noe
if numel(y) < numel(t)
    y = repmat(y, [1, floor(numel(t)/numel(y))]);
    y = [y, zeros(1, (numel(t) - numel(y)))];
end

if numel(y) > numel(t)
    y = y(1:numel(t));
end
