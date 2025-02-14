% Calculate pulse number for autoN when manual trigger setup is selected
function N = calculate_pulse_number(app, cam_name)

% Get DAQ and select correct camera
dq_session = app.getDevice("DAQ");
[~, cam] = select_devices(app, [], cam_name);

% Get wfm_data and timing 
wfm = dq_session.wfm_data.do(arrayfun(@(x) strcmp(dq_session.remove_al(x.port), cam.trigger), dq_session.wfm_data.do));
timing_data.rate = dq_session.global_props.rate; % Rate shouldn't actually matter for calculation of rising edges
timing_data.total_time = dq_session.global_props.total_time;

% Calculate waveform vectors
waveform = ones(1,round(timing_data.total_time*timing_data.rate));
waveform(1) = 0; % Count first pulse if coming at the very start 
for i = 1:numel(wfm)
    waveform = waveform .* Calculate_Waveform(dq_session, timing_data, wfm(i));
end

% Calculate number of rising edges 
N = sum(diff(waveform) == 1);

end