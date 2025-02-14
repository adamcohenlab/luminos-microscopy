function success = multiple_waveform_scan_js(app, inputs)
arguments
    app Rig_Control_App
    inputs struct
end

num_burst = str2num(inputs.repetitions);
scanParameters = inputs.scanParameters;
success = false;

dq = app.getDevice("DAQ");

scanValues = process_scan_inputs(num_burst, scanParameters);

% Execute scan bursts
for i = 1:num_burst

    update_scanning_params(app, scanParameters, scanValues, i);

    % Define folder name for each burst
    foldername = [inputs.folder, '_burst', num2str(i)];
    app.exp_complete = false;

    % Execute acquisition and wait for completion
    dq.Build_Waveforms();
    Waveform_Standalone_Acquisition_JS(app, foldername);
    while ~app.exp_complete
        pause(0.1);
    end
    pause(1);
end

success = true;
end
