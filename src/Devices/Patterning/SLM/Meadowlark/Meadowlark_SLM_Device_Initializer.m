classdef Meadowlark_SLM_Device_Initializer < SLM_Device_Initializer
    properties
        lut_file
        gpu_available
        Coverglass_Voltage double
    end
    methods
        function obj = Meadowlark_SLM_Device_Initializer()
            obj@SLM_Device_Initializer();
        end
    end
end
