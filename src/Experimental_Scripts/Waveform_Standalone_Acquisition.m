function Waveform_Standalone_Acquisition(app, options)
arguments
    app
    options.tag = '';
end
dq_session = app.getDevice('DAQ');
app.makeExperimentFolder(options.tag);
dq_session.DAQ_Master = true;

app.assignMasterDevice(dq_session);
app.assignDevicesForMonitoring([dq_session]); %,cf]);

dq_session.Start_Tasks();

end
