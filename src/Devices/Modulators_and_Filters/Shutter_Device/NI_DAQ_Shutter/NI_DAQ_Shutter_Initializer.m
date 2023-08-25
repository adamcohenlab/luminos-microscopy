classdef NI_DAQ_Shutter_Initializer < Shutter_Device_Initializer
    properties
        port string
    end
    methods
        function obj = NI_DAQ_Shutter_Initializer()
            obj@Shutter_Device_Initializer();
        end
    end
end
