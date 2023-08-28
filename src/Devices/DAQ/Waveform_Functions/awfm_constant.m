function y = awfm_constant(t, value)

% [DEFAULTS] add default values and units below
% value, 0, V
% [END]

y = value * ones(1, numel(t));
y(end) = 0;
end
