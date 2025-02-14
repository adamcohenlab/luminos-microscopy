function cycle = dwfm_2cycles(t, dltT1, tOn1, phase1, nPulses1, dltT2, tOn2, phase2, nPulses2)
% [DEFAULTS]
% dltT1, 1
% tOn1, 1
% phase1, 0
% nPulses1,
% dltT2, 1
% tOn2, 1
% phase2, 0
% nPulses2,
% [END]
dltT1 = defcheck(dltT1, 1);
tOn1 = defcheck(tOn1, 1);
phase1 = defcheck(phase1, 0);
nPulses1 = defcheck(nPulses1, t/dltT1);
dltT2 = defcheck(dltT2, 1);
tOn2 = defcheck(tOn2, 1);
phase2 = defcheck(phase2, 0);
nPulses2 = defcheck(nPulses2, t/dltT2);
rate = 1 / t(2);
pulseWidth = 20; %~0.2 ms

cycle1 = [];
OnSamp1 = round(tOn1*rate);
OffSamp1 = round(dltT1*rate) - OnSamp1;

for i = 1:nPulses1
    cycle1 = [cycle1, (ones(1, pulseWidth)), ...
        (zeros(1, OnSamp1-pulseWidth)), ...
        (ones(1, pulseWidth)), ...
        (zeros(1, OffSamp1-pulseWidth))];
end
cycle1 = [zeros(1, round(dltT1*rate*phase1-OnSamp1/2)), cycle1];

cycle2 = [];
OnSamp2 = round(tOn2*rate);
OffSamp2 = round(dltT2*rate) - OnSamp2;
for i = 1:nPulses2
    cycle2 = [cycle2, (ones(1, pulseWidth)), ...
        (zeros(1, OnSamp2-pulseWidth)), ...
        (ones(1, pulseWidth)), ...
        (zeros(1, OffSamp2-pulseWidth))];
end
cycle2 = [zeros(1, round(dltT2*rate*phase2-OnSamp2/2)), cycle2];

cycle = zeros(1, max(length(cycle1), length(cycle2)));
flag = length(cycle1) > length(cycle2);
if flag
    cycle(1:length(cycle2)) = cycle2;
    cycle = cycle + cycle1;
else
    cycle(1:length(cycle1)) = cycle1;
    cycle = cycle + cycle2;
end

if numel(cycle) < numel(t)
    cycle = [cycle, zeros(1, (numel(t) - numel(cycle)))];
end
if numel(cycle) > numel(t)
    cycle = cycle(1:numel(t));
end
cycle(end) = 0;
end
