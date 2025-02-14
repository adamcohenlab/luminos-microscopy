function cycle = dwfm_interleaved(t, dltT, tCell, tPulse, phase, n_cycle)
% [DEFAULTS] add default values and units below
% dltT, 1
% tCell, 0.6
% tPulse, 0.01
% phase, 0.5
% n_cycle, 5
% [END]
dltT = defcheck(dltT, 1);
tCell = defcheck(tCell, 0.6);
tPulse = defcheck(tPulse, 0.01);
phase = defcheck(phase, 0.5);
n_cycle = defcheck(n_cycle, 5);

rate = 1 / t(2);
pulseWidth = 10; %~0.1 ms

cycle1 = [];
dltT1 = dltT / 2;
OnSamp1 = round(tCell*rate);
OffSamp1 = round(dltT*rate) - OnSamp1;

for i = 1:n_cycle
    cycle1 = [cycle1, (ones(1, pulseWidth)), ...
        (zeros(1, OnSamp1-pulseWidth)), ...
        (ones(1, pulseWidth)), ...
        (zeros(1, OffSamp1-pulseWidth))];
end
cycle1 = [zeros(1, round(dltT1*rate*phase-OnSamp1/2)), cycle1];

cycle2 = [];
dltT2 = dltT1;
OnSamp2 = round(tPulse*rate);
OffSamp2 = round(dltT2*rate) - OnSamp2;
for i = 1:n_cycle
    cycle2 = [cycle2, (ones(1, pulseWidth)), ...
        (zeros(1, OnSamp2-pulseWidth)), ...
        (ones(1, pulseWidth)), ...
        (zeros(1, OffSamp2-pulseWidth)), ...
        (ones(1, pulseWidth)), ...
        (zeros(1, OnSamp2-pulseWidth)), ...
        (ones(1, pulseWidth)), ...
        (zeros(1, OffSamp2+pulseWidth))];
end
cycle2 = [zeros(1, round(dltT1*rate*phase-OnSamp2/2)), cycle2];


cycle = zeros(1, max(length(cycle1), length(cycle2)));
flag = length(cycle1) > length(cycle2);
if flag
    cycle(1:length(cycle2)) = cycle2;
    cycle = cycle | cycle1;
else
    cycle(1:length(cycle1)) = cycle1;
    cycle = cycle | cycle2;
end

if numel(cycle) < numel(t)
    cycle = [cycle, zeros(1, (numel(t) - numel(cycle)))];
end
if numel(cycle) > numel(t)
    cycle = cycle(1:numel(t));
end
cycle(end) = 0;

end
