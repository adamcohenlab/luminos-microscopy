function success = multiple_snap_scan_js(app, inputs, cam_name)
arguments
    app Rig_Control_App
    inputs
    cam_name
end

success = false;
num_burst = str2num(inputs.repetitions);
scanParameters = inputs.scanParameters;
cam_name = cam_name.camname;

[~, cam] = select_devices(app, [], cam_name);

app.makeExperimentFolder([inputs.folder + "_Snap"]);
dq_session = app.getDevice("DAQ");
dq_session.waveforms_built = false;

scanValues = process_scan_inputs(num_burst, scanParameters);

if app.screen_blanked == true
    app.blank_all_screens();
end

for i = 1:num_burst
    disp(i);
    update_scanning_params(app, scanParameters, scanValues, i);

    snaps(:, :, i) = cam.Snap();

    pause(cam.exposuretime);
end

disp("Saving file to " + strcat(app.expfolder, '\frames1.bin'));

% To Add: save positions of z-stage or xy(z) stage, depending on what's
% scanned
fileID = fopen(strcat(app.expfolder, '\frames1.bin'), 'w');
fwrite(fileID, snaps, 'uint16');
fclose(fileID);

if app.screen_blanked
    app.screen_blanked = false;
    % Briefly toggle to trigger listener if running.
    pause(0.05);
    app.screen_blanked = true;
end

success = true;
end
