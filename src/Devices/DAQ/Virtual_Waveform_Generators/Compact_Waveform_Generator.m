classdef Compact_Waveform_Generator < handle & matlab.mixin.SetGetExactNames
    properties
        Active_Params
        wfm_func_arguments
        sample_rate = 1
        time = 0
        axis
    end
    properties (SetObservable)
        wfm_func
        Active_Waveform_Index
        Waveform_Structure = wfm_handle.empty;
    end
    properties (SetAccess = private)
        t_vec
    end

    methods
        function obj = Compact_Waveform_Generator(options)
            arguments
                options.Waveform_Structure = [];
                options.numchannels = 1;
            end
            if ~isempty(options.Waveform_Structure)
                obj.Waveform_Structure = options.Waveform_Structure;
            else
                for i = 1:options.numchannels
                    obj.Waveform_Structure(i) = wfm_handle();
                end
            end
        end

        function Write_to_WFM(obj)
            fparams = [{obj.t_vec}, obj.wfm_func_arguments];
            obj.Waveform_Structure(str2double(obj.Active_Waveform_Index)).data = feval(erase(obj.wfm_func, '.m'), fparams{:});
        end

        function Plot_Waveforms(obj)
            for i = 1:numel(obj.Waveform_Structure)
                plot(obj.axis, obj.Waveform_Structure(i).data, 'DisplayName', ['Waveform_', num2str(i)])
                hold(obj.axis, 'on')
            end
            %legend(obj.axis)
            hold(obj.axis, 'off')
        end

        function wavemat = Get_Waveform_Mat(obj)
            wavemat = cell2mat({obj.Waveform_Structure.data}');
        end

        function set.sample_rate(obj, val)
            obj.sample_rate = val;
            obj.update_tvec();
        end
        function set.time(obj, val)
            obj.time = val;
            obj.update_tvec();
        end

    end
    methods (Access = private, Hidden = true)
        function update_tvec(obj)
            obj.t_vec = 0:1 / obj.sample_rate:obj.time - 1 / obj.sample_rate;
        end
    end
end
