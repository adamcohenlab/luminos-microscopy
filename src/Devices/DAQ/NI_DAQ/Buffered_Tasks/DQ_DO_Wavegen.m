classdef DQ_DO_Wavegen < DQ_Buffered_Task
    properties
    end
    methods
        function obj = timercallback(obj, src, event)
            obj.complete = true;
        end
    end

    methods
        function obj = DQ_DO_Wavegen(numsamples, rate, options)
            arguments
                numsamples
                rate
                options.timeout = 10.0;
                options.trigger_source = '';
                options.triggeredge = 'rising';
                options.clock_source = ' ';
                options.clockedge = 'rising';
                options.min = 0;
                options.max = 1;
                options.aibuffer_pad = 0;
                options.Create_Task = 1;
            end
            op_pass = options;
            task_type = 'doc';
            obj@DQ_Buffered_Task(numsamples, rate, task_type, op_pass);
            obj.clock_type = 'finite';
        end

        function obj = Configure_Channels(obj)
            for i = 1:numel(obj.channels)
                [status] = DAQ_MEX('Add_Digital_Output_Channel', obj.objPointer, ...
                    char(obj.channels(i).phys_channel), char(obj.channels(i).name), ...
                    uint8(obj.channels(i).data), int32(numel(obj.channels(i).data)));
                obj.ErrorCheck(status);
            end
        end

        function obj = Configure_Task(obj)
            obj = Configure_Task@DQ_Buffered_Task(obj);
            obj.Write_Buffer(0);
        end

        function obj = Write_Buffer(obj, autostart)
            status = DAQ_MEX('Write_Data', obj.objPointer);
            if autostart
                obj.Start();
            end
            obj.ErrorCheck(status);
        end

    end

end
