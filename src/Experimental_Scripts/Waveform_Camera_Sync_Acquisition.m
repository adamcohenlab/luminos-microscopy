function Waveform_Camera_Sync_Acquisition(app, bin, options)
arguments
    app Rig_Control_App
    bin
    options.tag = '';
end
app.exp_complete = false;
app.makeExperimentFolder(options.tag);
dq_session = app.getDevice('DAQ');
cam = app.getDevice('Camera');
DMD = app.getDevice('DMD');
cfcl = app.getDevice('Scanning_Device');
if ~isempty(cfcl)
    cfcl.camera_detection = 1;
end
Laser = app.getDevice('Laser_Device');
if numel(cam) > 1
    assert(~contains(cam(2).clock, 'Ctr'), 'Master Camera Cannot Use A Counter as a Clock! Change to equivalent PFI.')
    dq_session.clock = char(cam(2).clock);
    cam_clock_rate = cam(2).hsync_rate;
else
    %dq_session.trigger=char(cam.trigger); Removed this safety to allow
    %other readout modes. Will put back in with an if-switch later. -HD
    dq_session.clock = char(cam.clock);
    cam_clock_rate = cam.hsync_rate;
end

if ~strcmp(cam(1).frametrigger_source, "Off")
    dq_session.DAQ_Master = false;
end

if ~isempty(dq_session.buffered_tasks)
    app.assignMasterDevice(dq_session);
    app.assignDevicesForMonitoring([cfcl, cam, DMD, dq_session]);
    for i = 1:numel(cam)
        if ~isempty(cam(i).vsync)
            dq_session.Counter_Inputs(i) = DQ_Edge_Count(cam(i).vsync, dq_session.buffered_tasks(1).numsamples, cam_clock_rate, 'name', ['Camera', num2str(i), 'Frame Counter']);
        end
    end
    if ~strcmp(cam(1).frametrigger_source, "Off")
        %dq_session.trigger='/Dev1/PFI15';
        if strcmp(cam(1).frametrigger_source, "DAQ")
            if ~isempty(cam(1).hsync_rate)
                dq_session.Add_Dedicated_Camtrig_Counter(cam(1).daqtrig_period_ms, cam(1).daqTrigCounter, cam(1).clock, '', 'camera_hsync_rate_khz', cam(1).hsync_rate/1000);
            else
                dq_session.Add_Dedicated_Camtrig_Counter(cam(1).daqtrig_period_ms, cam(1).daqTrigCounter, cam(1).clock, '');
            end
        end
    end
    dq_session.Configure_Simple_Sync_Finite();
else
    if numel(cam) > 1
        app.assignMasterDevice(cam(1));
    else
        app.assignMasterDevice(cam);
    end
    app.assignDevicesForMonitoring([cam, DMD, Laser]);
    
end
if app.VR_On
    app.VRclient = tcpclient('localhost', 5001);
    writeline(app.VRclient, "start");
end
for i = 1:numel(cam)
    cam(i).Prepare_Sync_Aq(cam(i).Get_Exposure(), cam(i).Get_ROI(), bin);
end
for i = 1:numel(cam)
    cam(i).Start_Acquisition(cam(i).frames_requested, strcat(app.expfolder, ['\frames', num2str(i)]));
end
dq_session.Start_Tasks();
if strcmp(cam(1).frametrigger_source, "DAQ")
    dq_session.Dedicated_Camtrig_Counter.Start();
end

% wait until done
while ~app.exp_complete
    pause(0.5);
end
end
