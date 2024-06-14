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
warning('off','all')
SLM = app.getDevice('SLM_Device');
cfcl = app.getDevice('Scanning_Device');
if ~isempty(cfcl)
    cfcl.camera_detection = 1;
end
Laser = app.getDevice('Laser_Device');
warning('on','all')
if numel(cam) > 1
    assert(~contains(cam(1).clock, 'Ctr'), 'Master Camera Cannot Use A Counter as a Clock! Change to equivalent PFI.')
    %dq_session.clock = char(cam(1).clock);
    if ~isempty(strip(dq_session.clock))
        clock_rate = cam(1).hsync_rate;
    else
        clock_rate = dq_session.rate;
    end
else
    %dq_session.trigger=char(cam.trigger); Removed this safety to allow
    %other readout modes. Will put back in with an if-switch later. -HD
  %  dq_session.clock = char(cam.clock);
    if ~isempty(strip(dq_session.clock))
        clock_rate = cam.hsync_rate;
    else
        clock_rate = dq_session.rate;
    end
end

if ~strcmp(cam(1).frametrigger_source, "Off") && ~isempty(cam(1).clock) % Still make DAQ master if no cam clock.
    dq_session.DAQ_Master = false;
end

if ~isempty(dq_session.buffered_tasks)
    app.assignMasterDevice(dq_session);
    app.assignDevicesForMonitoring([cfcl, cam, DMD, SLM, dq_session]);

    if ~isempty(cam(1).clock) % Don't set counter for camera clock pulses if no camera clock exists.
        for i = 1:numel(cam)
            if ~isempty(cam(i).vsync)
                dq_session.Counter_Inputs(i) = DQ_Edge_Count(cam(i).vsync, dq_session.buffered_tasks(1).numsamples, clock_rate, 'name', ['Camera', num2str(i), 'Frame Counter']);
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
    else
        if ~strcmp(cam(1).frametrigger_source, "External")
            
            % Set up DAQ waveform for clockless camera that expects DAQ
            % triggering, unless External framesource is expected.
            Cam_Trigger_timing_data.rate = dq_session.rate;
            Cam_Trigger_timing_data.total_time = dq_session.numsamples/dq_session.rate;
            %max((cam.frames_requested+1)*cam.exposuretime,(cam.frames_requested+1)*cam.daqtrig_period_ms/1000);
            % Ideally there should be a buffer of one or more extra pulses
            % at the end of the recording so the camera collects the right
            % number of frames, but channels need to be the same size - 6/24 DI
            Cam_Trigger_wfminfo.port = char(cam.trigger);
            Cam_Trigger_wfminfo.name = strrep(Cam_Trigger_wfminfo.port, '/', '');;
    
            Cam_Trigger_wfminfo.wavefile = 'dwfm_pulse';
            params = cell(4,1);
                % Set up with correct number of pulses depending on mode.
                % DAQ: One pulse each frame as given by Frame Trigger.
                if strcmp(cam(1).frametrigger_source, "DAQ") 
                    params{1} = cam.daqtrig_period_ms/1000;
                    params{2} = 0.0100; params{3} = 0.0100;
                    params{4} = cam.frames_requested+2;
                % Off: Just give one pulse at start of recording.
                else 
                    params{1} = Cam_Trigger_timing_data.total_time;
                    params{2} = cam.exposuretime*0.01; params{3} = cam.exposuretime*0.01;
                    params{4} = 1;
                end
            Cam_Trigger_wfminfo.params = params;
            
            %Calculated_WF = Calculate_Waveform(dq_session, Cam_Trigger_timing_data, Cam_Trigger_wfminfo);
            %figure; plot(Calculated_WF);
            
            Build_Waveforms_Type(dq_session, Cam_Trigger_wfminfo, Cam_Trigger_timing_data, 'do');
        end
    end
    dq_session.Configure_Simple_Sync_Finite();
else
    if numel(cam) > 1
        app.assignMasterDevice(cam(1));
    else
        app.assignMasterDevice(cam);
    end
    app.assignDevicesForMonitoring([cam, DMD, SLM, Laser]);
    
end
if app.VR_On
    app.VRclient = tcpclient('localhost', 5001);
    writeline(app.VRclient, "start");
end
for i = 1:numel(cam)
    cam(i).Prepare_Sync_Aq(cam(i).exposuretime, cam(i).getROIForAcquisition(), bin);
end

for i = 1:numel(cam)
    cam(i).Start_Acquisition(cam(i).frames_requested, strcat(app.expfolder, ['\frames', num2str(i)]));
end
pause(1);
dq_session.Start_Tasks();
if strcmp(cam(1).frametrigger_source, "DAQ") && ~isempty(cam(1).clock)
    dq_session.Dedicated_Camtrig_Counter.Start();
end

if cam.name == "Simulated_Cam"
    app.exp_complete = 1;
    pause(cam.exposuretime*cam.frames_requested);
end

% wait until done
while ~app.exp_complete
    pause(0.5);
end

% restart camera at the end (Always do this for Kinetix Cam)
for i = 1:numel(cam)
    cam(i).Set_ROI(int32([cam(i).ROI(1), cam(i).ROI(2), cam(i).ROI(3), cam(i).ROI(4)]));
end

end

