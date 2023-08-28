function status = Scanning_Snap(app, tag)
cf = app.getDevice('Scanning_Device');
snap = cf.Snap();
snap.ref2d.ImageSize = size(snap.img);
snap.ref2d.XWorldLimits = [min(snap.xdata), max(snap.xdata)];
snap.ref2d.YWorldLimits = [min(snap.ydata), max(snap.ydata)];
ds = datestr(now, 'HHMMSS');
snapfolder = fullfile(app.datafolder, 'Snaps');
if ~exist(snapfolder, 'dir')
    mkdir(snapfolder)
end
snapimfile = fullfile(snapfolder, strcat(ds, tag, '.tiff'));
snapdatfile = fullfile(snapfolder, strcat(ds, tag, '.mat'));
pause(.01);
drawnow;
imwrite(snap.img, snapimfile);
save(snapdatfile, 'snap', '-v7.3');
Save_Snap_To_JS(app, snap.img, tag, ds);
status = 0;
end