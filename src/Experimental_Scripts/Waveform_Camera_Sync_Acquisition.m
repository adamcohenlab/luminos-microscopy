% Generalized acquisition script for use with multiple cameras with DO, CTR
% or PFI triggering. This should work on every rig with flexible choices for triggering.
% - DI 11/24

function Waveform_Camera_Sync_Acquisition(app, bin, options)
arguments
    app Rig_Control_App
    bin
    options.tag = '';
end

app.exp_complete = false;
dq_session = app.getDevice('DAQ');
cam = app.getDevice('Camera');
additional_pulses = [];
dq_session.Build_Waveforms();
% Don't warn if optional devices aren't present
warning("off","all");
DMD = app.getDevice('DMD');
SLM = app.getDevice('SLM_Device');
cfcl = app.getDevice('Scanning_Device');
zstage = app.getDevice('Linear1D_Controller');
stage = app.getDevice('Linear_Controller');
if ~isempty(cfcl)
    cfcl.camera_detection = 1;
end
Laser = app.getDevice('Laser_Device');
warning("on","all");

% Check if there is enough space left on disk for acquisition to avoid
% camera bugs
check_memory(app);

% Find all non-slave cameras and clock cam if selected cam clock as clock
clock_cam = [];
num = 1;
for i = 1:numel(cam)
    if cam(i).slave == false
       main_cam(num) = cam(i);
       num = num + 1;
    end
    
    if strcmp(strrep(dq_session.clock, '/', ''), strrep(cam(i).clock, '/', ''))
       clock_cam = cam(i);
    end
end


% Use camera clock rate instead if camera clock PFI is selected as source
if ~isempty(clock_cam) && ~isempty(clock_cam.hsync_rate)
    if contains(clock_cam.clock, 'CTR')
        error('Master Camera Cannot Use A Counter as a Clock! Change to equivalent PFI.');
    else 
        disp("Clock source is camera. Ignoring user input and using hsync_rate defined in rig initializer.");
        clock_rate = clock_cam.hsync_rate;
    end
else % If internal triggering or non-camera triggered, use user defined rate
    clock_rate = dq_session.rate;
end


% If available, set up camera frame counters
for i = 1:numel(cam)
    if ~isempty(cam(i).vsync)  %  Weird bug with 2 cameras: Using full length counter returns [empty]. Investigate later.
        
        if ~contains(cam(i).vsync, "CTR")
            dq_session.Counter_Inputs(i) = DQ_Edge_Count(cam(i).vsync, dq_session.buffered_tasks(1).numsamples*0.95, clock_rate, 'name', ['Camera', num2str(i), 'Frame Counter']);
        else
            error("vsync for " + cam(i).name + " is not a CTR in rig initializer. If this is a CTR SRC rename by CTR + number.");
        end
    end
end

% Set up camera triggering
for i = 1:numel(main_cam)

    % Frame trigger Off: Single pulse at the start of the experiment 
    if strcmp(main_cam(i).frametrigger_source, "Off")

        % Check if camera trigger port is DO, CTR or PFI
        if contains(main_cam(i).trigger, "line") % trigger is DO 
            % Retrieve camera trigger port from rig initializer
            Cam_Trigger_wfminfo.port = char(main_cam(i).trigger);
            Cam_Trigger_wfminfo.name = strrep(Cam_Trigger_wfminfo.port, '/', '');

            % Check if waveforms already have task defined for this camera
            for idx = 1:length(dq_session.wfm_data.do)
                if strcmp(main_cam(i).trigger, dq_session.remove_al(dq_session.wfm_data.do(idx).port))
                    error("Waveform already set for " + main_cam(i).name + " trigger port " +  Cam_Trigger_wfminfo.port + ". Delete waveform or use manual trigger mode.");
                end
            end
                
            % Set DO waveform with single trigger at the start
            Cam_Trigger_timing_data.rate = clock_rate;
            Cam_Trigger_timing_data.total_time = dq_session.numsamples/clock_rate;
            Cam_Trigger_wfminfo.wavefile = 'dwfm_pulse';
            params = cell(4,1);
            params{1} = Cam_Trigger_timing_data.total_time;
            params{2} = 0.001; params{3} = 0.001;
            params{4} = 1; % Single 1ms pulse at the start of the recording
            Cam_Trigger_wfminfo.params = params;

            % Add generated waveform to existing DOs 
            DO_idx = [];
            for idx = 1:length(dq_session.buffered_tasks)
                if isa(dq_session.buffered_tasks(idx), 'DQ_DO_Finite')
                    DO_idx = idx;
                    break; 
                end
            end
    
            Build_Waveforms_Type(dq_session, Cam_Trigger_wfminfo, Cam_Trigger_timing_data, 'do');
            if ~isempty(DO_idx)
                dq_session.buffered_tasks(DO_idx).channels(end+1) = dq_session.buffered_tasks(end).channels; % Performing surgery on a grape
                dq_session.buffered_tasks(end) = [];
            end

        % Send single pulse at the start of the recording
        elseif contains(main_cam(i).trigger, "PFI")  % trigger is PFI
            % Send additional pulses to all master cameras that need
            % them if DAQ is set to self-trigger.
            if ~strcmp(strrep(dq_session.trigger, '/', ''), strrep(main_cam(i).trigger, '/', ''))
                if dq_session.DAQ_Master
                    disp("DAQ trigger is not set to camera trigger. Sending additional start pulse to " + main_cam(i).name + " trigger port " + main_cam(i).trigger + "."); 
                    if isempty(additional_pulses)
                        additional_pulses = main_cam(i).trigger;
                    else
                        additional_pulses(end + 1) = main_cam(i).trigger;
                    end
                end
            end
            
        elseif contains(main_cam(i).trigger, "CTR") % trigger is CTR
            % This is fine as is, keep going.

        elseif isempty(main_cam(i).trigger)
            error("Camera trigger is not defined in rig initializer file. Set to run acquisition.");

        else 
            error("Camera trigger is not validly defined in rig initializer file. Set up correctly run acquisition.");

        end


    elseif strcmp(main_cam(i).frametrigger_source, "DAQ")

        % Check if camera trigger port is DO, CTR OUT/PFI 
        if contains(main_cam(i).trigger, "line") % trigger is DO 

            % Retrieve camera trigger port from rig initializer
            Cam_Trigger_wfminfo.port = char(main_cam(i).trigger);
            Cam_Trigger_wfminfo.name = strrep(Cam_Trigger_wfminfo.port, '/', '');

            % Check if waveforms already have task defined for this camera
            for idx = 1:length(dq_session.wfm_data.do)
                if strcmp(main_cam(i).trigger, dq_session.remove_al(dq_session.wfm_data.do(idx).port))
                    error("Waveform already set for " + main_cam(i).name + " trigger port " +  Cam_Trigger_wfminfo.port + ". Delete waveform or use manual trigger mode.");
                end
            end

            % Set DO waveform pulses at specified DAQ trigger rate
            Cam_Trigger_timing_data.rate = clock_rate;
            Cam_Trigger_timing_data.total_time = dq_session.numsamples/clock_rate;
            Cam_Trigger_wfminfo.wavefile = 'dwfm_pulse';
            params = cell(4,1);
            params{1} = main_cam.daqtrig_period_ms/1000;
            params{2} = 0.0100; params{3} = 0.0100;
            params{4} = NaN; % Undefined number of pulses fills whole waveform with pulses that are 1% of requested exposure time
            Cam_Trigger_wfminfo.params = params;

            % Add generated waveform to existing DOs 
            DO_idx = [];
            for idx = 1:length(dq_session.buffered_tasks)
                if isa(dq_session.buffered_tasks(idx), 'DQ_DO_Finite')
                    DO_idx = idx;
                    break; 
                end
            end
    
            Build_Waveforms_Type(dq_session, Cam_Trigger_wfminfo, Cam_Trigger_timing_data, 'do');
            if ~isempty(DO_idx)
                dq_session.buffered_tasks(DO_idx).channels(end+1) = dq_session.buffered_tasks(end).channels; 
                dq_session.buffered_tasks(end) = [];
            end

        % Set up CTR OUT pulses. If this is a normal PFI instead of a 
        % CTR OUT the DAQ with throw an error here.
        elseif contains(main_cam(i).trigger, "PFI") % trigger is PFI

            % If hsync_rate value is defined in json use it. If not use
            % default 100kHz.
            if ~isempty(main_cam(i).hsync_rate) 
                dq_session.Add_Dedicated_Camtrig_Counter(main_cam(i).daqtrig_period_ms, main_cam(i).daqTrigCounter, main_cam(i).clock, '', 'camera_hsync_rate_khz', main_cam(i).hsync_rate/1000);
            else
                dq_session.Add_Dedicated_Camtrig_Counter(main_cam(i).daqtrig_period_ms, main_cam(i).daqTrigCounter, main_cam(i).clock, '');
                warning("No hsync rate set for " + main_cam(i).name + " in rig initalizer. Assuming default 100kHz for DAQ CTR triggering.");
            end

        elseif isempty(main_cam(i).trigger)
            error("Camera trigger is not defined in rig initializer file. Set to run acquisition.");

        else 
            error("Camera trigger is not validly defined in rig initializer file. Set up correctly run acquisition.");
        end

    elseif strcmp(main_cam(i).frametrigger_source, "External")

        % Can't use manual triggering with CTR OUT/PFI, needs to be DO line
        if contains(main_cam(i).trigger, "CTR") || contains(main_cam(i).trigger, "PFI") % trigger is not DO
            error("Manual triggering requires DO output (port/line). Not compatible with PFI or CTR.");

        % Add check for whether a waveform is built for cam trigger if line
        elseif ~contains(main_cam(i).trigger, "line") 
            % Not a line is possible if triggering from external source.
            % Not necessarily an error but warn user.
            warning("Trigger line not specified in rig initializer. Make sure camera actually gets trigger inputs for each frame.");

        else
            % Check if waveforms have task defined for this camera.
            waveform_sent = false;
            for idx = 1:length(dq_session.wfm_data.do)
                if strcmp(main_cam(i).trigger, dq_session.remove_al(dq_session.wfm_data.do(idx).port))
                    waveform_sent = true;
                end
            end
            if ~waveform_sent 
                warning("No waveform set up for triggering camera. Make sure camera actually gets trigger inputs for each frame.");
            end    
        end 
    end
end

% Make folder for experiment if no errors so far
app.makeExperimentFolder(options.tag);

% Edge case: No waveforms with compeletly external triggering
if isempty(dq_session.buffered_tasks) && isempty(dq_session.Dedicated_Camtrig_Counter)
    if numel(cam) > 1
        % Use first master cam to check if acquisition finished
        app.assignMasterDevice(main_cam(1)); 
        main_cam(1).setMasterDevice(1);
        % Careful: Currently weird behavior from Kinetix and
        % Hamamatsu cams, return acq_done immediately even in master modex.
    else
        app.assignMasterDevice(cam);
    end

    % Only devices with relevant static values or patterns
    app.assignDevicesForMonitoring([cam, DMD, SLM, Laser, zstage, stage]); 
    no_waveforms = true;

else
    % All relevant devices
    app.assignDevicesForMonitoring([cfcl, cam, DMD, SLM, Laser, dq_session, zstage, stage]);
    % 
    app.assignMasterDevice(dq_session);

    % Send waveforms to DAQ
    dq_session.Configure_Simple_Sync_Finite();
    no_waveforms = false;
    for i = 1:numel(cam)
        cam(i).setMasterDevice(0);
    end
end

% Use VR if requested
if app.VR_On
    app.VRclient = tcpclient('localhost', 5001);
    writeline(app.VRclient, "start");
end

% Prepare cameras for acquisition
for i = 1:numel(cam)
    cam(i).Prepare_Sync_Aq(cam(i).exposuretime, cam(i).getROIForAcquisition(), bin(i));
end

% Blank screens if requested
if app.screen_blanked == true
    app.blank_all_screens();
end

% Put cameras in acquisition mode, now waiting for trigger inputs
for i = 1:numel(cam)
    cam(i).Start_Acquisition(cam(i).frames_requested, strcat(app.expfolder, ['\frames', num2str(i)]));
end
pause(0.5);

% Start DAQ waveforms and trigger if self-triggered selected.
% If trigger type is external in waveforms tab, DAQ will wait for 
% input pulse to that port. Send additional pulse to cameras that wouldn't 
% get pulse with current settings if 
if ~no_waveforms
    dq_session.Start_Tasks(additional_pulses);
end

% Start counters for CTR-based (DAQ) triggering 
for i = 1:numel(dq_session.Dedicated_Camtrig_Counter)
    dq_session.Dedicated_Camtrig_Counter(i).Start();
end

% Wait until Master device completes experiment. 
% exp_complete will trigger expFinishedCallback routine in Rig_Control_App.

start_timer(app);

% Experiment completed.
end

function  start_timer(app)
if ~app.exp_complete
    t = timer;
    t.StartDelay = 0.5;
    t.TimerFcn = @(~, ~) start_timer(app);
    start(t);
else
    cam = app.getDevice("Camera");
    % Restart camera streams at the end of the experiment if not done already
    for i = 1:numel(cam)
        cam(i).restartCamera();
        pause(0.25);
        cam(i).restartCamera();
        pause(0.25);
    end
    dq_session = app.getDevice("DAQ");
    % Stop counters for CTR-based (DAQ) triggering 
    for i = 1:numel(dq_session.Dedicated_Camtrig_Counter)
        dq_session.Dedicated_Camtrig_Counter(i).StopTask();
    end
    
    % Send TTL pulse to selected DO port upon completion of acquisition
    output_trigger_port = dq_session.completion_trigger;
    if ~isempty(output_trigger_port) % Don't send if 'None' is selected.
        output_trigger_signal = DQ_DO_On_Demand(0, output_trigger_port);
        output_trigger_signal.OD_Write(1);
        pause(.01); %Output 10ms pulse at the end of experiment to specified port
        output_trigger_signal.OD_Write(0);
    end
end
end

% % Check for duplicate ports with different exposure times on 'DAQ'
% for i = 1:numel(cams)
%     for j = 1:i-1
%         if strcmp(char(cams(i).trigger), char(cams(j).trigger)) && strcmp(cams(i).frametrigger_source, "DAQ") && strcmp(cams(j).frametrigger_source, "DAQ")
%             if cams(i).exposuretime ~= cams(j).exposuretime
%                 error('Exposure time for cameras %d and %d on port %s must be the same.', j, i, char(cams(i).trigger));
%             end
%         end
%     end
% end