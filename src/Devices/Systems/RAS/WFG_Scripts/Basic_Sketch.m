interfaceObj = visa('tek', 'USB::0x0699::0x0343::C020734::INSTR');
interfaceObj.OutputBufferSize = 51200;

%%
sampleRate = 500e8;
f1 = 10;
timeVec = 0:1 / sampleRate:1000 / sampleRate;
timeVec = timeVec(1:end-1);
waveform = mod((1:numel(timeVec)), 100) / 100;
waveform = waveform ./ max(waveform);

%%
binblock = zeros(2*waveformLength, 1);
binblock(2:2:end) = bitand(waveform, 255);
binblock(1:2:end) = bitshift(waveform, -8);
binblock = binblock';

% Build binary block header
bytes = num2str(length(binblock));
header = ['#', num2str(length(bytes)), bytes];
% Resets the contents of edit memory and define the length of signal
fprintf(myFgen, ['DATA:DEF EMEM, ', num2str(length(timeVec)), ';']); %1001
fprintf(interfaceObj, ['DATA:DEF EMEM, ', num2str(length(timeVec)), ';']); %1001
fwrite(interfaceObj, [':TRACE EMEM, ', header, binblock, ';']);
fwrite(interfaceObj, [':TRACE EMEM, ', header, binblock, ';'], 'uint8');
fprintf(interfaceObj, 'SOUR1:FUNC EMEM');
fprintf(interfaceObj, 'SOUR1:FREQ:FIXed 1Hz')
fprintf(interfaceObj, ':OUTP1 ON')