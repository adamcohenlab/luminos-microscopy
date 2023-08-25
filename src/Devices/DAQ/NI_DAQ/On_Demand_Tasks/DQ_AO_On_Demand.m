classdef DQ_AO_On_Demand < DQ_On_Demand_Task
    properties
        timeout
        min
        max
    end

    methods
        function obj = DQ_AO_On_Demand(init_data, phys_channels, options)
            arguments
                init_data
                phys_channels
                options.timeout = 10.0;
                options.min = -10;
                options.max = 10;
                options.init_data = 0;
            end
            obj@DQ_On_Demand_Task(phys_channels);
            obj.min = options.min;
            obj.max = options.max;
            obj.timeout = options.timeout;
            [status] = daq.ni.NIDAQmx.DAQmxCreateAOVoltageChan(obj.taskHandle, ...
                char(obj.phys_channels), char(0), ...
                obj.min, obj.max, daq.ni.NIDAQmx.DAQmx_Val_Volts, char(daq.ni.NIDAQmx.NULL));
            obj.ErrorCheck(status);
            obj.data = init_data;
        end

        function obj = OD_Write(obj, data)
            [status, reserved] = daq.ni.NIDAQmx.DAQmxWriteAnalogScalarF64(obj.taskHandle, uint32(1), ...
                obj.timeout, data, uint32(daq.ni.NIDAQmx.NULL));
            obj.ErrorCheck(status);
        end
    end
    methods (Static)
        function ErrorCheck(status)
            ErrorCheck@DQ_On_Demand_Task(status);
        end
    end
end
