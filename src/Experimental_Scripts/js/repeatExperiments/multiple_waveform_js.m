function success = multiple_waveform_js(app, inputs)
arguments
    app Rig_Control_App
    inputs
end
num_burst = str2num(inputs.repetitions);
success = false;
dq = app.getDevice("DAQ");

for i = 1:num_burst
    foldername = [inputs.folder, '_burst', num2str(i)];
    app.exp_complete = false;
    dq.Build_Waveforms();
    Waveform_Camera_Sync_Acquisition(app, bin, 'tag', foldername);
    while (~app.exp_complete)
        pause(.1)
    end
    pause(1);
end
success = true;
end