function y = dwfm_2cyclesFF(t, period1, toffset1, nPulses1, period2, toffset2, nPulses2)
% [DEFAULTS]
% dltT1, 1
% phase1, 0
% nPulses1,
% dltT2, 1
% phase2, 0
% nPulses2,
% [END]
period1 = defcheck(period1, 0.00127);
toffset1 = defcheck(toffset1, 0);
nPulses1 = defcheck(nPulses1, t/period1);
period2 = defcheck(period2, 0.00127);
toffset2 = defcheck(toffset2, 0.00127*0.8);
nPulses2 = defcheck(nPulses2, t/period2);
rate = 1 / t(2);
pulseWidth = round(0.00127*0.05 /  t(2));
blankSamps1 = round(period1*rate) - pulseWidth;
blankSamps2 = round(period2*rate) - pulseWidth;

y1 = [];
y2 = [];

for i = 1:nPulses1
    y1 = [y1, (zeros(1, blankSamps1)), ...
        (ones(1, pulseWidth))];
end
for i = 1:nPulses2
    y2 = [y2, (zeros(1, blankSamps2)), ...
        (ones(1, pulseWidth))];
end

y1 = circshift(y1, round(toffset1*rate));
y2 = circshift(y2, round(toffset2*rate));

if numel(y1) < numel(t)
    y1 = [y1, zeros(1, (numel(t) - numel(y1)))];
end
if numel(y2) < numel(t)
    y2 = [y2, zeros(1, (numel(t) - numel(y2)))];
end

if numel(y1) > numel(t)
    y1 = y1(1:numel(t));
end
if numel(y2) > numel(t)
    y2 = y2(1:numel(t));
end

y = y1 + y2;
y(end) = 0;
end
