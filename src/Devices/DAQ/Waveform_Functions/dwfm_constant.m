function y = dwfm_constant(t, value)
% [DEFAULTS] add default values and units below
% value, 0
% [END]
value = defcheck(value, 0);
y = value * ones(1, numel(t));
y(end) = 0;
end
