% Hadamard patterns are expected to have been sent to dmd.pattern_stack

function Waveform_Camera_Sync_Hadamard(app, bin, dmd, cam, options)
arguments
    app Rig_Control_App
    bin
    dmd
    cam
    options.tag = '';
end

dq_session = app.getDevice('DAQ');

% Check if waveforms already have task defined for the DMD trigger
waveform_sent = false;
for idx = 1:length(dq_session.wfm_data.do)
    if strcmp(dmd.trigger_channel, dq_session.remove_al(dq_session.wfm_data.do(idx).port))
        waveform_sent = true;
    end
end

% Build DMD Waveform if trigger channel known and no waveform built in
% waveforms tab yet
if ~isempty(dmd.trigger_channel) && ~waveform_sent
    DMD_Trigger_wfminfo.port = char(dmd.trigger_channel); % Use DMD that was selected in Luminos
    DMD_Trigger_wfminfo.name = strrep(DMD_Trigger_wfminfo.port, '/', '');
    DMD_Trigger_wfminfo.wavefile = 'dwfm_pulse';
    DMD_Trigger_wfminfo.params = cell(4,1);
    
    DMD_Trigger_wfminfo.params{1} = cam.exposuretime; % Use the camera that was used as input to control DMD
    DMD_Trigger_wfminfo.params{2} = 0.0100; DMD_Trigger_wfminfo.params{3} = 0.0100;
    DMD_Trigger_wfminfo.params{4} = size(dmd.pattern_stack,3);
    
    if ~isempty(dq_session.wfm_data.do)
        dq_session.wfm_data.do(end + 1) = DMD_Trigger_wfminfo;
    else
        dq_session.wfm_data.do = DMD_Trigger_wfminfo;
    end

elseif ~isempty(dmd.trigger_channel) && waveform_sent

    disp("DMD trigger using waveform from waveform tab.");

elseif isempty(dmd.trigger_channel)

    warning("DMD trigger is not set in rig initializer. Add or set up manually in waveforms tab.");

end

% Set up acquisition with as many frames as Hadamard patterns
cam.frames_requested = size(dmd.pattern_stack,3);
Waveform_Camera_Sync_Acquisition(app, bin,  'tag', options.tag);

end

