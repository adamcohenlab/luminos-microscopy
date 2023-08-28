classdef Device_System_Initializer < Device_Initializer
    properties
        slave_device_inits Initializer_Storage
    end
    methods
        function obj = Device_System_Initializer()
            obj@Device_Initializer();
        end
    end
end
