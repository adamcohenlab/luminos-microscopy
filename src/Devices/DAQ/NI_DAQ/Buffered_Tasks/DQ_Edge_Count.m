classdef DQ_Edge_Count < DQ_Buffered_Task
    properties
        counter
        data
        name
    end

    methods
        function obj = timercallback(obj, src, event)
            obj = obj.Read_Data();
            obj = obj.StopTask();
            drawnow
            pause(.1)
            obj.complete = true;
        end
    end

    methods
        function obj = DQ_Edge_Count(counter, numsamples, rate, options)
            arguments
                counter
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
                options.name = '';
            end
            task_type = 'cif';
            obj@DQ_Buffered_Task(numsamples, rate, task_type, options);
            obj.counter = counter;
            obj.clock_type = 'finite';
            obj.name = options.name;
        end
        function Configure_Channels(obj)
            status = DAQ_MEX('Add_Input_Channel', obj.objPointer, char(obj.counter), char(obj.name), int32(obj.numsamples));
            obj.ErrorCheck(status);
        end
        function obj = Read_Data(obj)
            [status, data_out] = DAQ_MEX('Read_Data', obj.objPointer);
            obj.data = data_out;
            obj.ErrorCheck(status);
        end
    end
end
