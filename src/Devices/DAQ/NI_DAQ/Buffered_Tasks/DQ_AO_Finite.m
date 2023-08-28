classdef DQ_AO_Finite < DQ_Buffered_Task
    properties
    end

    methods
        function obj = timercallback(obj, src, event)
            isTaskDone = uint32(0);
            while isTaskDone == uint32(0)
                [status, isTaskDone] = DAQ_MEX('TaskDone?', obj.objPointer);
                obj.ErrorCheck(status);
            end
            obj.StopTask();
            obj.ClearTask();
            obj.complete = true;
        end
    end

    methods
        function obj = DQ_AO_Finite(numsamples, rate, options)
            arguments
                numsamples
                rate
                options.timeout = 10.0;
                options.trigger_source = '';
                options.triggeredge = 'rising';
                options.clock_source = ' ';
                options.clockedge = 'rising';
                options.min = -10;
                options.max = 10;
                options.aibuffer_pad = 0;
            end
            op_pass = options;
            task_type = 'aof';
            obj@DQ_Buffered_Task(numsamples, rate, task_type, op_pass);
            obj.clock_type = 'finite';
        end

        function obj = Configure_Channels(obj)
            for i = 1:numel(obj.channels)
                status = DAQ_MEX('Add_Analog_Output_Channel', obj.objPointer, ...
                    char(obj.channels(i).phys_channel), char(obj.channels(i).name), ...
                    obj.channels(i).min, obj.channels(i).max, int32(-1), obj.channels(i).data, ...
                    int32(obj.numsamples));
                obj.ErrorCheck(status);
            end
        end

        function obj = Configure_Task(obj)
            obj = Configure_Task@DQ_Buffered_Task(obj);
            obj.Write_Buffer(0);
        end

        function obj = Write_Buffer(obj, autostart)
            status = DAQ_MEX('Write_Data', obj.objPointer);
            obj.ErrorCheck(status);
        end

    end

end
