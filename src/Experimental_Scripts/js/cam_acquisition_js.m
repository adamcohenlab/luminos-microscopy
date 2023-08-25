% This function is called when the user clicks the "Start Acquisition" button
function cam_acquisition_js(app, options)
folder = options.folder;
% Check whether waveforms have been built. If not, exit without
% running acquisition. Needs fixing to allow free acquisition. ATTENTION HD
dq_session = app.getDevice("DAQ");
if isempty(dq_session.waveforms_built) || dq_session.waveforms_built == false
    error("Waveforms don't exist. Please create waveforms on Waveforms tab. No data acquired.");
end
Waveform_Camera_Sync_Acquisition(app, 1, 'tag', folder);
dq_session.waveforms_built = false;
end