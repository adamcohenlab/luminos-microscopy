function y = awfm_constant(t, value)

% [DEFAULTS] add default values and units below
% value, 0, V
% [END]

value = defcheck(value, 0); % voltage, V
y = value * ones(1, numel(t));
y(end) = 0;
end
