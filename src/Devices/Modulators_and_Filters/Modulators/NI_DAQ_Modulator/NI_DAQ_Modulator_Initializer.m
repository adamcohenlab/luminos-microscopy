classdef NI_DAQ_Modulator_Initializer < Modulator_Device_Initializer
    properties
        port string
    end
    methods
        function obj = NI_DAQ_Modulator_Initializer()
            obj@Modulator_Device_Initializer();
        end
    end
end
