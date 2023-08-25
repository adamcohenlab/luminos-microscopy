classdef Modulator_Device_Initializer < Device_Initializer
    properties
        min double
        max double
    end
    methods
        function obj = Modulator_Device_Initializer()
            obj@Device_Initializer();
        end
    end
end
