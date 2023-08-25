function seq = dmdWriteStaticImage(api, device, img)
PicNum = int32(1);
PicOffset = int32(0);
BitPlanes = int32(1);
seq = alpsequence(device);
seq.alloc(BitPlanes, PicNum);
% seq.control(api.DATA_FORMAT,api.DATA_BINARY_TOPDOWN);
seq.control(api.BIN_MODE, api.BIN_UNINTERRUPTED);
seq.timing(10E6-2E-6, 10E6, 0, 0, 0);
seq.put(PicOffset, PicNum, img);
device.projcontrol(api.PROJ_MODE, api.MASTER);
device.startcont(seq);
end
