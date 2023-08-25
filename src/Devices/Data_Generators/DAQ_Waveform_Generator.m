classdef DAQ_Waveform_Generator < handle
    properties
        dq_session DAQ
        WFM_Devices
        display_ax
        total_time
        rate
        clock_groups
        trigger_groups
        wfms(1, :) DAQ_wfm
    end

    methods
        function obj = Plot_Waveform_Data(obj)
            num_samples = obj.total_time * obj.rate;
            tvec = linspace(0, 1/obj.rate*(num_samples - 1), num_samples);
            datamat = [];
            active_out_wfms = obj.wfms([strcmp(obj.wfms.type(2), 'o')] & [~strcmp('', {obj.wfms.name})]);
            out_namelist = strjoin({active_out_wfms.name}, ',');
            for i = 1:numel(active_out_wfms)
                fparams = [tvec, obj.wfms(i).func_params];
                data = feval(obj.wfms(i).func_name, fparams{:});
                if numel(data) < numel(tvec)
                    data = repmat(data, [1, ceil(numel(tvec)/numel(data))]);
                end
                if numel(data) > numel(tvec)
                    data = data(1:numel(tvec));
                end
                datamat = horzcat(datamat, data');
            end
            if ~isempty(out_namelist)
                for i = 1:size(datamat, 2)
                    plot(obj.display_ax, tvec, datamat(:, i));
                    hold(obj.display_ax, 'on')
                end
                hold(obj.display_ax, 'off')
                legend(obj.display_ax, strsplit(out_namelist, ','), 'TextColor', [.7, .7, .7])
            end
        end
    end

    methods
        function obj = DAQ_Waveform_Generator(app)
            arguments
                app Rig_Control_App
            end
            obj.dq_session = app.getDevice('DAQ');
            obj.WFM_Devices = app.Devices([app.Devices.daq_waveform_control]);

        end
    end
end