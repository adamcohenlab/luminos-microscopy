% random image
% alp_patterns = uint8(rand(1, 768, 1024) > 0.5 ) * uint8(255);
alp_patterns = uint8(ones(768, 1024)*255);

% device.stop;
% device.halt;


% possibly change these later
CameraLines = 1;
PicNum = 1;
PicOffset = 0;
ExposureMilliseconds = 1;
BitPlanes = 1;

seq = alpsequence(device);
seq.alloc(BitPlanes, PicNum);
seq.control(api.DATA_FORMAT, api.DATA_BINARY_TOPDOWN);
seq.control(api.BIN_MODE, api.BIN_UNINTERRUPTED)

PictureTimeSpacing = ceil(ExposureMilliseconds*128/5); % [us] % 128/5
TriggerInDelay = -30 + ceil(9.75*ceil(CameraLines/2)); % [us] only relevant in slave mode
PictureTimeExcess = 50; % [us] % must be > 2 us per instructions. not a dmd parameter, for parameter calculation only

TriggerSynchDelay = api.DEFAULT; % [us] only relevant in master mode
TriggerSynchPulseWidth = api.DEFAULT; % [us]
PictureTime = floor(ExposureMilliseconds*1000/1.023) - PictureTimeSpacing; % [us]
IlluminateTime = PictureTime - TriggerInDelay - PictureTimeExcess - TriggerSynchDelay; % [us]
seq.timing(IlluminateTime, PictureTime, TriggerSynchDelay, TriggerSynchPulseWidth, TriggerInDelay);

seq.put(PicOffset, PicNum, alp_patterns);
% for external triggering
device.projcontrol(api.PROJ_MODE, api.SLAVE_VD);
% for internal triggering
device.projcontrol(api.PROJ_MODE, api.MASTER);

device.startcont(seq);


device.stop;
device.halt;
seq.free;
