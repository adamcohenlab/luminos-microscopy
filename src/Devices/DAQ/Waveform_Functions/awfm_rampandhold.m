function y = awfm_rampandhold(t, minval, maxval)
%     % a single linear increasing ramp

% [DEFAULTS]
% minval, 0, V
% maxval, 1, V
% [END]

minval = defcheck(minval, 0); % the minimal value, V
maxval = defcheck(maxval, 1); % the maximal value, V

y = minval + (maxval - minval) / max(t) * t;

end
