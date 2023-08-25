% setup_load_start_sequence sets up, loads and starts a sequence :)
% For controlling VIALUXes at the Cohen Lab.
%
% Use like this:
%
% 	alp_patterns = custom_patterns;
% 	ExposureMilliseconds = 5;
% 	CameraLines = 128;
% 	ModeStringSyncOrUninterrupted = 'sync';
% 	setup_load_start_sequence
%
% where api and device should be present in the calling environment.
% alp_patterns is a 3D matrix with patterns in binary top down format
% ExposureMilliseconds is the exposure time in ms
% CameraLines is the number of readout lines to be captured by the camera
% ModeStringSyncOrUninterrupted can be either 'sync' or 'uninterrupted',
% see below.
%
% Notes:
%
% This function has been prepared to use a delayed DMD trigger. To achieve
% synchronized projection and acquisition of frames, set a delay of 200 us
% in the DMD trigger, relative to the camera trigger. The reason for this
% is that we want the pattern exposure to finish exactly at the end of the
% camera global exposure, but there needs to be a time interval in between
% PictureTimes. This is solved by having a DMD trigge that always falls in
% the rolling shutter time.
%
% The uninterrupted mode allows to keep frames on for arbitrarily long
% periods, allowing to trigger the advance through a sequence of patterns
% for most applications. This mode however, switches frames as soon as a
% trigger is detected, which will introduce a deterministic but generally
% unavoidable rolling shutter artifact in the initial and final camera
% frame of the pattern exposure.
%
% 2016 Vicente Parot
% Cohen Lab - Harvard University

% the following combinations of parameters were tested and worked optimally
% Exposure = 5; % [ms]
% CameraLines = 112;
% PictureTimeSpacing = ceil(Exposure*128/5); % [us]
% TriggerInDelay = -30 + ceil(9.75*ceil(CameraLines/2)); % [us]
% PictureTimeExcess = 25; % [us] % must be > 2 us per instructions.

% Exposure = 10; % [ms]
% CameraLines = 112;

% Exposure = 20; % [ms]
% CameraLines = 112;

% Exposure = 20; % [ms]
% CameraLines = 400;

% Exposure = 2.5; % [ms]
% CameraLines = 400;
%
% 2016 Vicente Parot
% Cohen Lab - Harvard University

device.stop;
device.halt;

device.control(api.VD_EDGE, api.EDGE_RISING);

BitPlanes = 1;
PicOffset = 0;
PicNum = size(alp_patterns, 3);

PictureTimeSpacing = ceil(ExposureMilliseconds*128/5); % [us] % 128/5
TriggerInDelay = -30 + ceil(9.75*ceil(CameraLines/2)); % [us] only relevant in slave mode
PictureTimeExcess = 50; % [us] % must be > 2 us per instructions. not a dmd parameter, for parameter calculation only

TriggerSynchDelay = api.DEFAULT; % [us] only relevant in master mode
TriggerSynchPulseWidth = api.DEFAULT; % [us]
PictureTime = floor(ExposureMilliseconds*1000/1.023) - PictureTimeSpacing; % [us]
IlluminateTime = PictureTime - TriggerInDelay - PictureTimeExcess - TriggerSynchDelay; % [us]
fprintf('PictureTime: %d us\nIlluminateTime: %d us\n', PictureTime, IlluminateTime)

seq = alpsequence(device);
seq.alloc(BitPlanes, PicNum);
seq.control(api.DATA_FORMAT, api.DATA_BINARY_TOPDOWN);

% ModeStringSyncOrUninterrupted = 'uninterrupted';

switch ModeStringSyncOrUninterrupted
    case 'uninterrupted'
        seq.control(api.BIN_MODE, api.BIN_UNINTERRUPTED); % to display the pattern
        % until next trigger, even in slave mode, regardless of IlluminateTime.
        % Watch for bleedthrough into the rolling shutter due to delayed
        % responsivity.
    case 'sync' % do nothing
    otherwise % do nothing
end
seq.timing(IlluminateTime, PictureTime, TriggerSynchDelay, TriggerSynchPulseWidth, TriggerInDelay);
[~, PictureTime] = seq.inquire(api.PICTURE_TIME);
[~, IlluminateTime] = seq.inquire(api.ILLUMINATE_TIME);
fprintf('PictureTime: %d us\nIlluminateTime: %d us\n', PictureTime, IlluminateTime)
fprintf('Loading %d patterns ... ', PicNum)
seq.put(PicOffset, PicNum, permute(alp_patterns, [3, 1, 2]));
fprintf('done\n', PicNum)

device.projcontrol(api.PROJ_MODE, api.SLAVE_VD);
device.startcont(seq);

% sometime this was a function, not anymore
% function setup_load_start_sequence(api,device,alp_patterns,...
%     ExposureMilliseconds,CameraLines,ModeStringSyncOrUninterrupted)
% end