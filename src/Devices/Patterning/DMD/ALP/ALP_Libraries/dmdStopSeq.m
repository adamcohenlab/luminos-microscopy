function dmdStopSeq(device, seq)
device.stop;
device.halt;
seq.free;
end