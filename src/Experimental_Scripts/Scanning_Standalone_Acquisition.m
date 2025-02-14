function Scanning_Standalone_Acquisition(app, options)
arguments
    app
    options.tag = '';
end
cf = app.getDevice('Scanning_Device');
app.makeExperimentFolder(options.tag);
app.assignMasterDevice(cf);
app.assignDevicesForMonitoring(cf);
cf.Start_Tasks();

end
