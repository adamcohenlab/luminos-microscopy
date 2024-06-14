classdef Newport_84x_PE_Initializer < Power_Meter_Initializer
    properties
        COMPORT string
        Hot_Pluggable
    end
    methods
        function obj = Newport_84x_PE_Initializer()
            obj@Power_Meter_Initializer();
        end
    end
end
