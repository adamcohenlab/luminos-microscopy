function cycle = dwfm_roundRobin(t, dltT, tMask, phase, n_cycle)
% [DEFAULTS] add default values and units below
% dltT, 1
% tMask, 0.6
% phase, 0.5
% n_cycle, 5
% [END]
dltT = defcheck(dltT, 1);
tMask = defcheck(tMask, 0.6);
phase = defcheck(phase, 0.5);
n_cycle = defcheck(n_cycle, 5);

rate = 1 / t(2);
pulseWidth = 5; %~0.1 ms

cycle = [];

OnSamp = round(tMask*rate);
OffSamp = round(dltT*rate) - OnSamp;

for i = 1:n_cycle
    cycle = [cycle, (ones(1, pulseWidth)), ...
        (zeros(1, OnSamp-pulseWidth)), ...
        (ones(1, pulseWidth)), ...
        (zeros(1, OffSamp-pulseWidth))];
end
cycle = [zeros(1, round(dltT*rate*phase-OnSamp/2)), cycle];


if numel(cycle) < numel(t)
    cycle = [cycle, zeros(1, (numel(t) - numel(cycle)))];
end
if numel(cycle) > numel(t)
    cycle = cycle(1:numel(t));
end
cycle(end) = 0;
end
