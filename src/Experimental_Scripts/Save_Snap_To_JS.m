function Save_Snap_To_JS(app, snapim, experimentName, date)
% save a duplicate snap to basepath + /User_Interface/relay/imgs/[name]/[YYYYmmdd]/[HHMMSS].png

% create folder if it doesn't exist:
folder = fullfile(app.basepath, 'src', 'User_Interface', 'relay', 'imgs', app.User.name, datestr(now, 'YYYYmmdd'));

if ~exist(folder, 'dir')
    mkdir(folder);
end

snapfile = fullfile(folder, strcat(date, experimentName, '.png'));

% write as png:
im_double = double(snapim);
im_uint8 = im_double / max(im_double(:)) * (2^8 - 1); % map img to [0, 255]
imwrite(im_uint8, gray, snapfile, 'png');
end