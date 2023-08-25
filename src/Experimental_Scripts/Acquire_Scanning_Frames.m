function Acquire_Scanning_Frames(app, numframes, tag)
arguments
    app
    numframes
    tag
end
cf = app.getDevice('Scanning_Device');
app.makeExperimentFolder(tag);
app.assignMasterDevice(cf);
app.assignDevicesForMonitoring(cf);
cf.Acquire_Frames(numframes);

end