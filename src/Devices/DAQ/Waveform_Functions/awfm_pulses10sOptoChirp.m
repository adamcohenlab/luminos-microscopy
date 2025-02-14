function y = awfm_pulses10sOptoChirp(t, pulsnum, timss, amp, freq1, freq2, freq3, freq4, freq5, freq6)
% [DEFAULTS] add default values and units below
% pulsnum, 2
% timss
% amp, 1
% freq1, 1
% freq2, 1
% freq3, 1
% freq4, 1
% freq5, 1
% freq6, 1
% [END]
pulsnum = defcheck(pulsnum, 2); %number of pulses
freq1 = defcheck(freq1, 1);
amp = defcheck(amp, 1);
freq2 = defcheck(freq2, 1);
freq3 = defcheck(freq3, 1);
freq4 = defcheck(freq4, 1);
freq5 = defcheck(freq5, 1);
freq6 = defcheck(freq6, 1);


rate = 1 / t(2);
empty = round(1*rate);
downsamps1 = round((1 / freq1)*rate);
downsamps2 = round((1 / freq2)*rate);
downsamps3 = round((1 / freq3)*rate);
downsamps4 = round((1 / freq4)*rate);
downsamps5 = round((1 / freq5)*rate);
downsamps6 = round((1 / freq6)*rate);
upsamps = round(timss*rate);
y = [];

y = [y, repmat([zeros(1, downsamps1), amp + zeros(1, upsamps)], 1, pulsnum), zeros(1, empty), ...
    repmat([zeros(1, downsamps2), amp + zeros(1, upsamps)], 1, pulsnum), zeros(1, empty), ...
    repmat([zeros(1, downsamps3), amp + zeros(1, upsamps)], 1, pulsnum), zeros(1, empty), ...
    repmat([zeros(1, downsamps4), amp + zeros(1, upsamps)], 1, pulsnum), zeros(1, empty), ...
    repmat([zeros(1, downsamps5), amp + zeros(1, upsamps)], 1, pulsnum), zeros(1, empty), ...
    repmat([zeros(1, downsamps6), amp + zeros(1, upsamps)], 1, pulsnum), zeros(1, empty), ...
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
