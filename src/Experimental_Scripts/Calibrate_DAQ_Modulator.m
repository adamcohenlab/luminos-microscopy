function Calibrate_DAQ_Modulator(app, modulator_name, options)
arguments
    app Rig_Control_App
    modulator_name
    options.numpoints = 200;
    options.tag = '';
    options.pm_index = 1;
end
pm = app.getDevice('Power_Meter');
pm = pm(options.pm_index);
%pm.connect();
modulator = app.getDevice('NI_DAQ_Modulator', 'name', modulator_name);
app.makeExperimentFolder(options.tag);
app.assignMasterDevice(app);
app.assignDevicesForMonitoring([pm, modulator]);
testvec = linspace(modulator.min, modulator.max, options.numpoints);
curvevals = zeros(2, options.numpoints);
curvevals(1, :) = testvec;
for i = 1:options.numpoints
    modulator.level = testvec(i);
    pause(.3);
    storeval = zeros(1, 10);
    for j = 1:10
        storeval(j) =pm.readData(.1);
    end
    curvevals(2, i) = mean(storeval);
end
modulator.level = 0;
modulator.calibration_curve = curvevals;
notify(app, 'exp_finished');
end
