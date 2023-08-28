function save_cam_snap_js(app, options)
arguments
    app
    options.folder = ''
    options.devname = []
    options.show_date = true
end

% if there is more than 1 camera, select the first one
cams = app.getDevice("Camera", "name", options.devname);
if length(cams) > 1
    options.devname = cams(1).name;
end

Camera_Snap(app,options.folder,'devicename',options.devname, 'show_date', options.show_date);

end