function y = awfm_sin(t, A, freq, c, phase)
% [DEFAULTS]
% A, 1
% freq, 10
% c, 0
% phase, 0
% [END]
A = defcheck(A, 1);
freq = defcheck(freq, 10);
c = defcheck(c, 0);
phase = defcheck(phase, 0);
y = A * sin(t*2*pi*freq+phase*2*pi/360) + c;
end
