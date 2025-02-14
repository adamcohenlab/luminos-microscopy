function success = multiple_hilo_scan_js(app, inputs, dmd_name, cam_name)
arguments
    app Rig_Control_App
    inputs
    dmd_name
    cam_name
end

success = false;
num_burst = str2num(inputs.repetitions);
scanParameters = inputs.scanParameters;
dmd_name = dmd_name.devname;
cam_name = cam_name.camname;

[dmd, cam] = select_devices(app, dmd_name, cam_name);

app.makeExperimentFolder([inputs.folder + "_HiLo"]);
dq_session = app.getDevice("DAQ");
dq_session.waveforms_built = false;

scanValues = process_scan_inputs(num_burst, scanParameters);

% Initialize dmd
dmd.Write_White(); %Project Widefield

if app.screen_blanked == true
    app.blank_all_screens();
end

counter = 1;
for i = 1:num_burst
    update_scanning_params(app, scanParameters, scanValues, i);

    dmd.Write_White(); %Project Widefield

    pause(cam.exposuretime+0.1); % DMD takes a bit to refresh

    snaps(:, :, counter) = cam.Snap();
    counter = counter + 1;

    % Project speckle
    dmd.Target = round(rand(dmd.Dimensions));
    dmd.Write_Static();

    pause(cam.exposuretime+0.1) % Pause to not saturate the COM
    snaps(:, :, counter) = cam.Snap();

    counter = counter + 1;
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

