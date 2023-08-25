function output = Multi_Burst_Waveform_Camera_Sync_Acquisition(app, num_burst, options)
arguments
    app Rig_Control_App
    num_burst
    options.tag = '';
end
dq = app.getDevice("DAQ");
for i = 1:num_burst
    foldername = [options.tag, '_burst', num2str(i)];
    app.exp_complete = false;
    dq.Build_Waveforms();
    Waveform_Camera_Sync_Acquisition(app, 1, 'tag', foldername)
    while (~app.exp_complete)
        pause(.1)
    end
    pause(1);
end
output = 0;
end