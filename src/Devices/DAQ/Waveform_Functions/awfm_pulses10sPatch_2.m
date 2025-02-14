function y = awfm_pulses10sPatch_2(t, pulsnum, timss, t_before, amp1, freq1, freq2, freq3, freq4, freq5, freq6, freq7, freq8, freq9, freq10)
% [DEFAULTS] add default values and units below
% pulsnum, 2
% timss
% t_before, 1
% amp1, 1
% freq1, 1
% freq2, 1
% freq3, 1
% freq4, 1
% freq5, 1
% freq6, 1
% freq7, 1
% freq8, 1
% freq9, 1
% freq10, 1
% [END]
pulsnum = defcheck(pulsnum, 2); %number of pulses

t_before = defcheck(t_before, 1);
freq1 = defcheck(freq1, 1);
amp1 = defcheck(amp1, 1);
freq2 = defcheck(freq2, 1);
freq3 = defcheck(freq3, 1);
freq4 = defcheck(freq4, 1);
freq5 = defcheck(freq5, 1);
freq6 = defcheck(freq6, 1);
freq7 = defcheck(freq7, 1);
freq8 = defcheck(freq8, 1);
freq9 = defcheck(freq9, 1);
freq10 = defcheck(freq10, 1);


rate = 1 / t(2);
empty = round(1*rate);
downsamps1 = round((1 / freq1)*rate);
downsamps2 = round((1 / freq2)*rate);
downsamps3 = round((1 / freq3)*rate);
downsamps4 = round((1 / freq4)*rate);
downsamps5 = round((1 / freq5)*rate);
downsamps6 = round((1 / freq6)*rate);
downsamps7 = round((1 / freq7)*rate);
downsamps8 = round((1 / freq8)*rate);
downsamps9 = round((1 / freq9)*rate);
downsamps10 = round((1 / freq10)*rate);
upsamps = round(timss*rate);
y = [];

y = [y, repmat([amp1 + zeros(1, upsamps), zeros(1, downsamps1 - upsamps)], 1, 5-1), amp1 + zeros(1, upsamps), zeros(1, empty*t_interval-upsamps), ...
    repmat([amp1 + zeros(1, upsamps), zeros(1, downsamps2 - upsamps)], 1, 5-1), amp1 + zeros(1, upsamps), zeros(1, empty*t_interval-upsamps), ...
    repmat([amp1 + zeros(1, upsamps), zeros(1, downsamps3 - upsamps)], 1, pulsnum-1), amp1 + zeros(1, upsamps), zeros(1, empty*t_interval-upsamps), ...
    repmat([amp1 + zeros(1, upsamps), zeros(1, downsamps4 - upsamps)], 1, pulsnum-1), amp1 + zeros(1, upsamps), zeros(1, empty*t_interval-upsamps), ...
    repmat([amp1 + zeros(1, upsamps), zeros(1, downsamps5 - upsamps)], 1, pulsnum-1), amp1 + zeros(1, upsamps), zeros(1, empty*t_interval-upsamps), ...
    repmat([amp1 + zeros(1, upsamps), zeros(1, downsamps6 - upsamps)], 1, pulsnum-1), amp1 + zeros(1, upsamps), zeros(1, empty*t_interval-upsamps), ...
    repmat([amp1 + zeros(1, upsamps), zeros(1, downsamps7 - upsamps)], 1, pulsnum-1), amp1 + zeros(1, upsamps), zeros(1, empty*t_interval-upsamps), ...
    repmat([amp1 + zeros(1, upsamps), zeros(1, downsamps8 - upsamps)], 1, pulsnum-1), amp1 + zeros(1, upsamps), zeros(1, empty*t_interval-upsamps), ...
    repmat([amp1 + zeros(1, upsamps), zeros(1, downsamps9 - upsamps)], 1, pulsnum-1), amp1 + zeros(1, upsamps), zeros(1, empty*t_interval-upsamps), ...
    repmat([amp1 + zeros(1, upsamps), zeros(1, downsamps10 - upsamps)], 1, pulsnum-1), amp1 + zeros(1, upsamps), zeros(1, empty*t_interval-upsamps), ...
    ];

y = [zeros(1, empty*t_before), y];


% Check the size is the correct noe
if numel(y) < numel(t)
    y = repmat(y, [1, floor(numel(t)/numel(y))]);
    y = [y, zeros(1, (numel(t) - numel(y)))];
end

if numel(y) > numel(t)
    y = y(1:numel(t));
end
