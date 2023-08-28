function Acquire_Scanning_ZStack(app, thickness, numslices, avg_count, tag)
arguments
    app
    thickness
    numslices
    avg_count
    tag
end
cf = app.getDevice('Scanning_Device');
app.makeExperimentFolder(tag);
app.assignMasterDevice(cf);
app.assignDevicesForMonitoring(cf);
cf.Acquire_ZStack(thickness, numslices, avg_count);

end