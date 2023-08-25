classdef Newport_84x_PE_Initializer < Device_Initializer
    properties
        COMPORT string
        Hot_Pluggable double
    end
    methods
        function obj = Newport_84x_PE_Initializer()
            obj@Device_Initializer();
        end
    end
end
