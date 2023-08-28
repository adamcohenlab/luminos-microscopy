classdef DQ_AI_Finite < DQ_Buffered_Task
    properties
    end
    events
        data_refreshed
    end
    methods
        function obj = timercallback(obj, src, event)
            obj = obj.Read_Data();
            obj.StopTask();
            drawnow
            pause(.1)
            obj.ClearTask();
            obj.complete = true;
        end
    end
    methods
        function obj = DQ_AI_Finite(numsamples, rate, options)
            arguments
                numsamples
                rate
                options.timeout = 10.0;
                options.trigger_source = '';
                options.triggeredge = 'rising';
                options.rerouted_source = '';
                options.clock_source = ' ';
                options.clockedge = 'rising';
                options.read_data_threshold = rate;
                options.max = 10;
                options.min = -10;
                options.aibuffer_pad = 0;
                options.Create_Task = true;
            end
            op_pass = options;
            task_type = 'aif';
            obj@DQ_Buffered_Task(numsamples, rate, task_type, op_pass);
            obj.clock_type = 'finite';
        end

        function obj = Configure_Channels(obj)
            for i = 1:numel(obj.channels)
                status = DAQ_MEX('Add_Analog_Input_Channel', obj.objPointer, ...
                    obj.channels(i).phys_channel, obj.channels(i).name, ...
                    double(obj.channels(i).min), double(obj.channels(i).max), int32(-1), ...
                    int32(obj.numsamples));
                obj.ErrorCheck(status);
            end
        end

        function obj = Read_Data(obj)
            data = zeros(1, numel(obj.channels)*obj.numsamples);
            sampsread = int32(0);
            [status, data] = DAQ_MEX('Read_Data', obj.objPointer);
            obj.ErrorCheck(status);
            for i = 1:numel(obj.channels)
                obj.channels(i).data = data(((i - 1) * obj.numsamples + 1):i*obj.numsamples);
            end
        end
    end
end
