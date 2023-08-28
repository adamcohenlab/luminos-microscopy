classdef Voltage_Shutter_Initializer < Shutter_Device_Initializer
    properties
        port string
        offVoltage double
        onVoltage double
    end
    methods
        function obj = Voltage_Shutter_Initializer()
            obj@Shutter_Device_Initializer();
        end
    end
end
