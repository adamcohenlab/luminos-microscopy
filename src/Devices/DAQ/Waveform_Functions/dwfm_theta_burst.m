function y = dwfm_theta_burst(t, pulsnum, timss, freq1, freq2, freq3, freq4, freq5, freq6, t_interval)
% [DEFAULTS] add default values and units below
% pulsnum
% timss
% freq1
% freq2
% freq3
% freq4
% freq5
% freq6
% t_interval
% [END]

%this function is based on awfm_theta_burst
freq7 = 1;


pulsnum = defcheck(pulsnum, 2) %number of pulses
freq1 = defcheck(freq1, 100)
amp1 = 1
freq2 = defcheck(freq2, 20)
freq3 = defcheck(freq3, 10)
freq4 = defcheck(freq4, 5)
freq5 = defcheck(freq5, 3)
freq6 = defcheck(freq6, 2)

rate = 1 / t(2);
empty = round(1*rate) * t_interval;
downsamps1 = round((1 / freq1)*rate);
downsamps2 = round((1 / freq2)*rate);
downsamps3 = round((1 / freq3)*rate);
downsamps4 = round((1 / freq4)*rate);
downsamps5 = round((1 / freq5)*rate);
downsamps6 = round((1 / freq6)*rate);
downsamps7 = round((1 / freq7)*rate);

upsamps = round(timss*rate);


y = [];
y = [y, repmat([zeros(1, (downsamps1 - upsamps)), amp1 + zeros(1, upsamps)], 1, pulsnum)];
y1 = repmat([zeros(1, downsamps2-length(y)), y], 1, 5);
y2 = repmat([zeros(1, downsamps3-length(y)), y], 1, 5);
y3 = repmat([zeros(1, downsamps4-length(y)), y], 1, 5);
y4 = repmat([zeros(1, downsamps5-length(y)), y], 1, 5);
y5 = repmat([zeros(1, downsamps6-length(y)), y], 1, 5);
y6 = repmat([zeros(1, downsamps7-length(y)), y], 1, 5);


%y = [y repmat([zeros(1,downsamps3-length(y)) y],1,2)];
y = [zeros(1, round(1*rate)), y1, zeros(1, empty), y2, zeros(1, empty), y3, zeros(1, empty), y4, zeros(1, empty), y5, zeros(1, empty), y6];

y = [zeros(1, empty), y];


% Check the size is the correct noe
if numel(y) < numel(t)
    %y=repmat(y,[1 floor(numel(t)/numel(y))]);
    y = [y, zeros(1, (numel(t) - numel(y)))];
end

if numel(y) > numel(t)
    y = y(1:numel(t));
end
