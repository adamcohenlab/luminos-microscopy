function y = dwfm_pulses(t, width, spacing, phase)
% [DEFAULTS] add default values and units below
% width, 0.1, s
% spacing, 0.5, s
% phase, 0, s
% [END]

period = width + spacing;
    
% Use a modulo operation and a logical comparison to create the square wave
y = (mod(t + phase, period) < width);

y(end) = 0;
end
