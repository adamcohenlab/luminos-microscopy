function seq = dmdWriteTriggeredTransitionImages(api, device, imgs)
% seq = dmdWriteTriggeredTransitionImages(api, device, imgs)
%
% imgs: uint8, [N, width, height]
%
% This acquisition sets the trigger mode to STEP. The device transitions to
% the next frame on each rising edge of the trigger signal. The picture and
% illumination times are set to the minimum values to give the highest
% possible transition rate.
PicNum = size(imgs, 1);
PicOffset = 0;
BitPlanes = 1;
device.control(api.VD_EDGE, api.EDGE_RISING);
seq = alpsequence(device);
seq.alloc(BitPlanes, PicNum);
seq.control(api.DATA_FORMAT, api.DATA_BINARY_TOPDOWN);
seq.control(api.BIN_MODE, api.BIN_UNINTERRUPTED);
TriggerSynchDelay = api.DEFAULT; % [us] only relevant in master mode
TriggerSynchPulseWidth = api.DEFAULT; % [us]
TriggerInDelay = api.DEFAULT;
PictureTime = seq.inquire(api.MIN_PICTURE_TIME);
IlluminationTime = seq.inquire(api.MIN_ILLUMINATE_TIME);
seq.timing(IlluminationTime, PictureTime, TriggerSynchDelay, TriggerSynchPulseWidth, TriggerInDelay);
seq.put(PicOffset, PicNum, imgs);
device.projcontrol(api.PROJ_MODE, api.MASTER);
ALP_PROJ_STEP = int32(2329); % was missing from the matlab bindings
device.projcontrol(ALP_PROJ_STEP, api.EDGE_RISING)
device.startcont(seq);
end