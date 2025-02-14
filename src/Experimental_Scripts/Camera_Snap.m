function Camera_Snap(app, experimentName, options)
arguments
    app
    experimentName
    options.devicename = []
    options.show_date = true
end
cam = app.getDevice('Camera', 'name', options.devicename);
cam.Get_ROI();
snap = CL_RefImage();
% Get all available DMD devices
dmd = app.getDevice('DMD');

if ~isempty(dmd)
    snap.tform(length(dmd)).tform = affine2d();
    for i = 1:length(dmd)
        snap.tform(i).name = dmd(i).name;
        snap.tform(i).tform = dmd(i).tform;
    end
else
    % Handle case where no DMDs are found
    snap.tform = [];
end


snap.bin = cam.bin;
snap.img = cam.Snap();

% Reshape if depending on binning - DI 6/24
sizes_bin = size(snap.img)/snap.bin;
snap.img = reshape(snap.img(1:ceil(sizes_bin(1)/snap.bin),:)',sizes_bin(2),ceil(sizes_bin(1)/snap.bin)*snap.bin)';
extra_lines = ceil(sizes_bin(1)/snap.bin)*snap.bin - sizes_bin(1);
snap.img = snap.img(1:end-extra_lines,:);
%figure; imagesc(snap.img); disp(size(snap.img));

snap.type = 'Camera';
snap.name = cam.name;
snap.ref2d.ImageSize = size(snap.img);
snap.ref2d.XWorldLimits = double([cam.ROI(1), cam.ROI(1) + cam.ROI(2)]);
snap.ref2d.YWorldLimits = double([cam.ROI(3), cam.ROI(3) + cam.ROI(4)]);
snap.xdata = cam.ROI(1) + 1:cam.ROI(1) + cam.ROI(2);
snap.ydata = cam.ROI(3) + 1:cam.ROI(3) + cam.ROI(4);
snap.timestamp = datetime("now");
if options.show_date
    ds = datestr(now, 'HHMMSS');
else
    ds = '';
end

snapfolder = fullfile(app.datafolder, 'Snaps');
if ~exist(snapfolder, 'dir')
    mkdir(snapfolder)
end
snapimfile = fullfile(snapfolder, strcat(ds, experimentName, '.tiff'));
snapdatfile = fullfile(snapfolder, strcat(ds, experimentName, '.mat'));
pause(.01);
drawnow;
imwrite(snap.img, snapimfile);
save(snapdatfile, 'snap', '-v7.3');
Save_Snap_To_JS(app, snap.img, experimentName, ds);
end