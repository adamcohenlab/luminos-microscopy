% this is good to include to start off and initialize
if exist('seq', 'var') && seq.sequenceid
    dmdStopSeq(device, seq)
end
clear seq
clear device
clear api

% first run the device initialization, this function comes from Shanes code
% api_version: string, the class of api to load. Should be either,
%   'alpV42x64' or 'alpV43x64'
api_version = "alpV42x64";
[api, device] = init_dmd(api_version);

% now can control the DMD uisng the different functions

% write single image to DMD
img = zeros(768, 1024, 'uint8');
seq = dmdWriteStaticImage(api, device, img);

% stop displaying the image, or stop the current sequence
% good practice to always just initially check if a sequence exists to stop
dmdStopSeq(device, seq)

% write a sequence of images to switch between
% this is currently written to transition images on a trigger pulse to DMD
imgs = zeros(2, 768, 1024, 'uint8');
% imgs: uint8, [N, width, height]
seq = dmdWriteTriggeredTransitionImages(api, device, imgs);


% from Shane's Labview DMD code

% write white
if exist('seq', 'var') && seq.sequenceid
    dmdStopSeq(device, seq)
end
seq = dmdWriteStaticImage(api, device, zeros(device.width, device.height, 'uint8')+uint8(255));


% camera registration

% first load the registration files, these are previous transformations
f1 = "dmdToFlash_channel1.dat";
f2 = "dmdToFlash_channel2.dat";
T1 = dlmread(f1);
T2 = dlmread(f2);

% DMD register to camera

% first write registration squares
f = "dmdControlPts_channel1.dat";
if exist('seq', 'var') && seq.sequenceid
    dmdStopSeq(device, seq)
end
seq = dmdWriteRegistrationSquares(api, device, f);

% then it gets the points nd makes the transform
%pts1 = Camera Coordinates, taken from camera program, GetImageROIPointCoord
f1 = "dmdControlPts_channel1.dat";
f2 = "dmdToFlash_channel1.dat";
bPts = dlmread(f1);
tform = estimateGeometricTransform(pts1, bPts, 'affine');
% I don't know where this ^ function is?
T = tform.T;
dlmwrite(f2, T);
if exist('seq', 'var') && seq.sequenceid
    dmdStopSeq(device, seq)
end
clear seq


% then when you write an image, use the transform
img = false(device.width, device.height);
%input of the points from for example the camera roi
pts = T1.' * [pts; ones(1, size(pts, 2))];
img = or(img, poly2mask(pts(2, :), pts(1, :), 768, 1024));
%repeat for channel2 pts
pts = T2.' * [pts; ones(1, size(pts, 2))];
img = or(img, poly2mask(pts(2, :), pts(1, :), 768, 1024));
% then same as before
if exist('seq', 'var') && seq.sequenceid
    dmdStopSeq(device, seq)
end
seq = dmdWriteStaticImage(api, device, img);


% alot of this would depend on how the camera program is interfaced to
% since the point regions are usually determined by selecting on the camera
% display screen of some sort


% deinitialize!
% in Shane's code, the DMD cluster information (device, api, control pts?)
% get flattened and written to a json file that the computer can load later
% then just same as in beginning
if exist('seq', 'var') && seq.sequenceid
    dmdStopSeq(device, seq)
end
clear seq
clear device
clear api
