function delay = findDelay(waveform1, waveform2)
% calculate waveform autocorrelation
assert(numel(waveform1) == numel(waveform2));
len = numel(waveform1);
r = ifft(fft(waveform1).*conj(fft(waveform2)));
r = [r(end-len+2:end), r(1:len)]';

peakLoc = scanimage.util.peakFinder(r);
peakLoc(r(peakLoc) < 0.99*max(r(peakLoc))) = []; % filter out peaks to compensate for rounding errors
delay = min(peakLoc);
end