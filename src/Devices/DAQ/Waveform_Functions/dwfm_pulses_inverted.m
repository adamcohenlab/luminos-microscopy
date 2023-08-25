function y = dwfm_pulses_inverted(t, width, spacing, phase)
% [DEFAULTS] add default values and units below
% width, 0.01, s
% spacing, 0.5, s
% phase, 0, s
% [END]

period = width + spacing;
    
% Use a modulo operation and a logical comparison to create the square wave
y = (mod(t + phase, period) < width);

% flip y
y = ~y;

y(end) = 0;
end
