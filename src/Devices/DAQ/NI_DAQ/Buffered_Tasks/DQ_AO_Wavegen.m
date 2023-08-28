classdef DQ_AO_Wavegen < DQ_Buffered_Task
    properties
        regeneration_mode
        onboard_bufsize
        channels_configured
    end
    methods
        function obj = DQ_AO_Wavegen(numsamples, rate, options)
            arguments
                numsamples
                rate
                options.timeout = 10.0;
                options.trigger_source = '';
                options.triggeredge = 'rising';
                options.rerouted_source = '';
                options.clock_source = ' ';
                options.clockedge = 'rising';
                options.min = -10;
                options.max = 10;
                options.aibuffer_pad = 0;
                options.Create_Task = 1;
            end
            op_pass = options;
            task_type = 'aoc';
            obj@DQ_Buffered_Task(numsamples, rate, task_type, op_pass);
            obj.clock_type = 'continuous';
            obj.regeneration_mode = 'CPU';
        end

        function obj = Configure_Task(obj)
            obj = Configure_Task@DQ_Buffered_Task(obj);
            obj.channels_configured = 1;
            obj.Write_Buffer(0);
        end

        function obj = Configure_Channels(obj)
            for i = 1:numel(obj.channels)
                status = DAQ_MEX('Add_Analog_Output_Channel', obj.objPointer, ...
                    char(obj.channels(i).phys_channel), char(obj.channels(i).name), ...
                    obj.channels(i).min, obj.channels(i).max, int32(-1), double(obj.channels(i).data), ...
                    int32(obj.numsamples));
                obj.ErrorCheck(status);
            end
        end

        function obj = Write_Buffer(obj, autostart)
            status = DAQ_MEX('Write_Data', obj.objPointer);
            if autostart
                obj.Start();
            end
            obj.ErrorCheck(status);
        end

        function obj = Update_Buffer(obj)
            sampsPerChanWritten = int32(0);
            error('Update_Buffer Not Yet Supported by MEXDAQ')
            if obj.numsamples == numel(obj.channels(1).data)
                coherent_handoff = 1;
            else
                coherent_handoff = 0;
                warning('Buffer Size Mismatch. Task will quickly stop and restart.')
            end
            data = cell2mat({obj.channels.data});
            obj.StopTask();
            [status] = daq.ni.NIDAQmx.DAQmxCfgOutputBuffer(obj.taskHandle, uint32(obj.numsamples));
            obj.ErrorCheck(status);
        end
        function Start(obj)
            obj.complete = false;
            status = DAQ_MEX('Start_Task', obj.objPointer);
            obj.ErrorCheck(status);
        end
    end
end
