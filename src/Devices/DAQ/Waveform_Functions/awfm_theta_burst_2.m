% written by Pojeong Park

function y = awfm_theta_burst_2(t, pulsnum, timss, amp1, freq1, freq2, repeat_freq2, freq3, t_before)
% [DEFAULTS]
% pulsnum, 2, pulses
% timss, 0.1, s
% amp1, 1, V
% freq1, 100, Hz
% freq2, 5, Hz
% repeat_freq2, 5, Hz
% freq3, 0.2, Hz
% t_before, 1, s
% [END]

pulsnum = defcheck(pulsnum, 2); %number of pulses
freq1 = defcheck(freq1, 100);
amp1 = defcheck(amp1, 1);
freq2 = defcheck(freq2, 5);
freq3 = defcheck(freq3, 0.2);
t_before = defcheck(t_before, 1);
repeat_freq2 = defcheck(repeat_freq2, 5);


rate = 1 / t(2);
empty = round(1*rate);
downsamps1 = round((1 / freq1)*rate);
downsamps2 = round((1 / freq2)*rate);
downsamps3 = round((1 / freq3)*rate);

upsamps = round(timss*rate);


y = [];
y = [y, amp1 + zeros(1, upsamps)];
y = [y, repmat([zeros(1, (downsamps1 - upsamps)), amp1 + zeros(1, upsamps)], 1, pulsnum-1)];
y = [y, repmat([zeros(1, downsamps2-length(y)), y], 1, repeat_freq2)];
y = [y, repmat([zeros(1, downsamps3-length(y)), y], 1, 5)];
y = [zeros(1, round(empty*t_before)), y];


% Check the size is the correct noe
if numel(y) < numel(t)
    %y=repmat(y,[1 floor(numel(t)/numel(y))]);
    y = [y, zeros(1, (numel(t) - numel(y)))];
end

if numel(y) > numel(t)
    y = y(1:numel(t));
end
