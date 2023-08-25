% run waveforms without camera

function success = Waveform_Standalone_Acquisition_JS(app, folder)
arguments
    app Rig_Control_App
    folder = ""
end
% global_props: {total_time, rate, clock_source, trigger_source, folder}
% wfm_data: {ao, do, ai}
% ao/do/ai: [{port, name, wfminfo?,...}, ...]
dq = app.getDevice('DAQ');
% (TODO: add multi-device support)
app.exp_complete = false;
success = dq.Build_Waveforms();
app.makeExperimentFolder(folder);
dq.DAQ_Master = true;
app.assignMasterDevice(dq);
app.assignDevicesForMonitoring([dq]); %,cf]);

if app.VR_On
    try
        app.VRclient = tcpclient('localhost', 5001);
    catch err
        % if error starts with "cannot create...", then VR is not running
        if startsWith(err.message, "Cannot create a communication")
            error("VR is not running. Please start VR before running this experiment.")
        else
            rethrow(err)
        end
    end
    writeline(app.VRclient, "start")
end
dq.Start_Tasks();
% % wait until done
% while ~app.exp_complete
%     pause(0.5);
% end
end