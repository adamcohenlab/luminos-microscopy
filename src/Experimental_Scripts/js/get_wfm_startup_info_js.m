% Function to give all the waveform information to JS
function info = get_wfm_startup_info_js(app)
arguments
    app Rig_Control_App
end
dq_session = app.getDevice('DAQ');

info = struct();
info.ao_ports = get_full_port_name(dq_session.AO_Ports);
info.ai_ports = get_full_port_name(dq_session.AI_Ports);
info.do_ports = get_full_port_name(dq_session.DIO_Ports);

% add aliases for ports (e.g. "Dev1/ao0" --> "Modulator")
info.ao_ports = add_aliases(info.ao_ports);
info.ai_ports = add_aliases(info.ai_ports);
info.do_ports = add_aliases(info.do_ports);

% build list of waveform functions
wfm_function_path = fullfile(app.basepath, 'src\Devices\DAQ\Waveform_Functions');
analog_wfm_funcs_names = filenames_in_folder([wfm_function_path, '\awfm*.m']);
digital_wfm_funcs_names = filenames_in_folder([wfm_function_path, '\dwfm*.m']);

% get waveform info for all files in wfm_funcs using Get_WFM_Info

info.analog_wfm_funcs = {};
info.digital_wfm_funcs = {};

for i = 1:length(analog_wfm_funcs_names)
    info.analog_wfm_funcs{i} = Get_WFM_Info(analog_wfm_funcs_names{i});
end

for i = 1:length(digital_wfm_funcs_names)
    info.digital_wfm_funcs{i} = Get_WFM_Info(digital_wfm_funcs_names{i});
end

% get clock & trigger
port_list = dq_session.Terminals;

info.trigger_options = add_default(port_list, dq_session.default_trigger);
info.trigger_options = add_aliases(info.trigger_options);

info.clock_options = [{'Internal'}; port_list];
info.clock_options = add_default(info.clock_options, dq_session.defaultClock);
info.clock_options = add_aliases(info.clock_options);


% -------- helper functions --------

    function ports = get_full_port_name(port_struct)
    ports = strcat({port_struct.Device}, '/', {port_struct.PortID});
    end

    function filenames = filenames_in_folder(folder)
    filenames = dir(folder);
    filenames = {filenames.name};
    end

    function ports = add_aliases(ports)
    port_alias_list = dq_session.alias_list;

    for j = 1:size(port_alias_list, 1)
        aliasindex = find(strcmp(port_alias_list{j, 1}, ports));
        if ~isempty(aliasindex)
            ports{aliasindex} = port_alias_list{j, 2};
        end
    end
    end

% move the default to the top of the list
    function options = add_default(options, default)
    if strcmp(default,"")
        return
    end

    default_index = find(strcmp(default, options));
    if isempty(default_index)
        warning("Default value: [%s] not found in list of options",default)
        return
    end
    options = [options(default_index), options(1:default_index-1)', options(default_index+1:end)'];
    end

end