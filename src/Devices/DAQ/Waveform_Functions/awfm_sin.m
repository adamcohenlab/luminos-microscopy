function y = awfm_sin(t, Amplitude, freq, c, phase)
% [DEFAULTS]
% Amplitude, 1, V
% freq, 10, Hz
% c, 0, V
% phase, 0, deg
% [END]
y = Amplitude * sin(t*2*pi*freq+phase*2*pi/360) + c;
end
