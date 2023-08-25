classdef DQ_DO_On_Demand < DQ_On_Demand_Task
    properties
        timeout
    end
    methods
        function obj = DQ_DO_On_Demand(init_data, phys_channels, options)
            arguments
                init_data
                phys_channels
                options.timeout = 10.0;
                options.init_data = 0;
            end
            obj = obj@DQ_On_Demand_Task(phys_channels);
            obj.timeout = options.timeout;
            [status] = daq.ni.NIDAQmx.DAQmxCreateDOChan(obj.taskHandle, ...
                char(obj.phys_channels), char(0), ...
                int32(daq.ni.NIDAQmx.DAQmx_Val_ChanPerLine));
            obj.ErrorCheck(status);
            obj.data = uint8(init_data);
        end
        function obj = OD_Write(obj, data)
            sampsPerChanWritten = int32(0);
            [status, sampsPerChanWritten, reserved] = daq.ni.NIDAQmx.DAQmxWriteDigitalLines( ...
                obj.taskHandle, int32(1), uint32(1), obj.timeout, ...
                uint32(daq.ni.NIDAQmx.DAQmx_Val_GroupByChannel), uint8(data), ...
                sampsPerChanWritten, uint32(daq.ni.NIDAQmx.NULL));
            obj.ErrorCheck(status);
        end
    end
    methods (Static)
        function ErrorCheck(status)
            ErrorCheck@DQ_On_Demand_Task(status);
        end
    end
end
