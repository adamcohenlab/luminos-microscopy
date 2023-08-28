% This script controls the acquisition of confocal frames. If there is a
% DAQ-session waveform built, it will run an acquisition of both confocal
% and DAQ waveform data

% DAQ trigger and clock need to be set to the Ctr0
% and Ctr or corresponding frame counter and acquisition clock of your
% confocal setup.
% DAQ master must be false.

% If there is no waveform built,
% it will run only the confocal frames acquisition. It will save the
% resulting data in the experiment data directory, defined by the app, and
% will append the tag to the filename.
function Waveform_Scanning_Sync_Acquisition(app, tag)
arguments
    app Rig_Control_App
    tag
end
app.makeExperimentFolder(tag);
dq_session = app.getDevice('DAQ');
cf = app.getDevice('Scanning_Device');
cf.Synchronize_WFM_Data();
numframes = round((cf.sample_rate / numel(cf.galvox_wfm) + 1)*dq_session.buffered_tasks(1).numsamples/dq_session.buffered_tasks(1).rate); %Added additional second to cfcl acq for stability.
app.assignMasterDevice(dq_session);
dq_session.buffered_tasks(1).Connect_Terminals('/Dev2/ai/StartTrigger', '/Dev2/PFI3');
dq_session.buffered_tasks(1).Connect_Terminals('/Dev2/ai/SampleClock', '/Dev2/PFI6');
dq_session.Counter_Inputs(1) = DQ_Edge_Count('Dev1/Ctr0', dq_session.buffered_tasks(1).numsamples, dq_session.buffered_tasks(1).rate, 'name', 'Scanning Frame Counter');
pause(.5);
dq_session.Configure_Simple_Sync_Finite();
app.assignDevicesForMonitoring([cf, dq_session]);
dq_session.Start_Tasks();
cf.Acquire_Frames(numframes);

end
