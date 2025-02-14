function y = dwfm_PWM(t, n)
% [DEFAULTS] add default values and units below
% n
% [END]
sig = linspace(0, .8, numel(t)/n/2);
sig = downsample(sig, 10);
state = zeros(1, numel(t)/n/2);
trigval = zeros(1, numel(t)/n/2);
ticks_per_frame = 16;
for i = 0:numel(t) / n / 2 - 1
    if i == 0
        trigval(i+1) = 1;
        state(i+1) = 0;
    else
        if mod(i, ticks_per_frame) / ticks_per_frame < sig(floor(i/10)+1)
            state(i+1) = 1;
        end
    end
end

expandedsignal = zeros(1, numel(t)/n);
expandedsignal(1:2:end) = abs([1, diff(state)]);
expandedsignal(2:2:end) = 0;
y = expandedsignal;
y = repmat(y, [1, n]);
y(end) = 0;
end
