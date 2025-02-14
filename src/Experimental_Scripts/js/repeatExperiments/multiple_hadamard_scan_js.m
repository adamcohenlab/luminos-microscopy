function success = multiple_hadamard_scan_js(app, inputs, dmd_name, cam_name)
arguments
    app Rig_Control_App
    inputs struct
    dmd_name
    cam_name
end

success = false;
num_burst = str2num(inputs.repetitions);
scanParameters = inputs.scanParameters;
dmd_name = dmd_name.devname;
cam_name = cam_name.camname;

[dmd, cam] = select_devices(app, dmd_name, cam_name);

dq = app.getDevice("DAQ");
cams = app.getDevice("Camera");

for i = 1:numel(cams)
    bin(i) = cams(i).bin;
end

scanValues = process_scan_inputs(num_burst, scanParameters);

for i = 1:num_burst
    update_scanning_params(app, scanParameters, scanValues, i);

    foldername = [inputs.folder, '_Hadamard_burst', num2str(i)];
    app.exp_complete = false;
    dq.Build_Waveforms();
    Waveform_Camera_Sync_Hadamard(app, bin, dmd, cam, 'tag', foldername);
    while (~app.exp_complete)
        pause(.1)
    end
    pause(1);
end
success = true;
end