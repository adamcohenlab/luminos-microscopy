function y = awfm_rampUpHoldrampDown(t, holdt, minval, maxval)
%     % a single linear increasing ramp

% [DEFAULTS]
% holdt, 0, s
% minval, 0, V
% maxval, 1, V
% [END]

holdt = defcheck(holdt, 0); % time to hold in between ramps
minval = defcheck(minval, 0); % the minimal value, V
maxval = defcheck(maxval, 1); % the maximal value, V

rampt = (0.5 * (max(t) - holdt));
y = zeros(1, numel(t));
for i = 1:numel(t);
    if t(i) <= rampt
        y(i) = minval + (maxval - minval) / rampt * t(i);
    elseif t(i) <= rampt + holdt
        y(i) = maxval;
    else
        y(i) = maxval - (maxval - minval) / rampt * (t(i) - rampt - holdt);
    end
end

end
