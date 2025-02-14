function y = awfm_gated_sin(t, A, freq, wait, c, phase)
% [DEFAULTS]
% A, 1,
% freq, 10,
% wait, 0,
% c, 0,
% phase, 0,
% [END]

A = defcheck(A, 1);
freq = defcheck(freq, 10);
wait = defcheck(wait, 0);
c = defcheck(c, 0);
phase = defcheck(phase, 0);
rate = 1 / t(2);
y0 = zeros(1, length(t(1:ceil(wait*rate))));
y1 = (A .* sin(t(ceil(wait*rate)+1:end).*(2 * pi * freq) + phase * 2 * pi / 360)) + c;
y = cat(2, y0, y1);
end
