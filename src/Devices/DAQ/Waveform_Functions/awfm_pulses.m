function y = awfm_pulses(t, minVal, maxVal, width, spacing, phase)

% [DEFAULTS] add default values and units below
% minVal, 0, V
% maxVal, 1, V
% width, 0.1, s
% spacing, 0.5, s
% phase, 0, s
% [END]

period = width + spacing;
    
% Use a modulo operation and a logical comparison to create the square wave
y = (mod(t + phase, period) < width) * (maxVal - minVal) + minVal;
end