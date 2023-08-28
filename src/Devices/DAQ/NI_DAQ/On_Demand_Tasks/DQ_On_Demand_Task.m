classdef DQ_On_Demand_Task < handle & matlab.mixin.SetGetExactNames
    properties
        phys_channels
        name
        data
    end
    properties
        taskHandle
    end

    methods
        function obj = DQ_On_Demand_Task(phys_channels)
            obj.phys_channels = phys_channels;
            taskHandle = uint64(0);
            [status, obj.taskHandle] = daq.ni.NIDAQmx.DAQmxCreateTask(char(0), taskHandle);
            obj.ErrorCheck(status);
        end
        function obj = ClearTask(obj)
            [status] = daq.ni.NIDAQmx.DAQmxClearTask(obj.taskHandle);
            obj.ErrorCheck(status);
        end
        function set.data(obj, val)
            obj.data = uint8(val);
            obj.OD_Write(val);
        end
    end

    methods (Static)
        function ErrorCheck(status)
            daq.ni.utility.throwOrWarnOnStatus(status);
        end
    end

end
