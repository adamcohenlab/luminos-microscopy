classdef Power_Meter_Initializer < Device_Initializer
    properties
        autoconnect
    end
    methods
        function obj = Power_Meter_Initializer()
            obj@Device_Initializer();
        end
    end
end
