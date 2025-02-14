% This function is called when the user clicks the "Start Acquisition" button
function cam_acquisition_js(app, options)
folder = options.folder;
cam = app.getDevice('Camera');
for i = 1:numel(cam)
    binning(i) = cam(i).bin;
end
% Check whether waveforms have been built. If not, exit without
% running acquisition. Needs fixing to allow free acquisition. ATTENTION HD
dq_session = app.getDevice("DAQ");
dq_session.Build_Waveforms();
if isempty(dq_session.waveforms_built) || dq_session.waveforms_built == false
    error("Waveforms don't exist. Please create waveforms on Waveforms tab. No data acquired.");
end

dq_session.set_completion_trigger(dq_session.global_props.completion_trigger);

Waveform_Camera_Sync_Acquisition(app, binning, 'tag', folder);
dq_session.waveforms_built = false;
end