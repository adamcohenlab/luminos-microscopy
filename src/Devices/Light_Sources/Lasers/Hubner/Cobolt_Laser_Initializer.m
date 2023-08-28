classdef Cobolt_Laser_Initializer < Laser_Device_Initializer
    properties
        COMPORT string
    end
    methods
        function obj = Cobolt_Laser_Initializer()
            obj@Laser_Device_Initializer();
        end
    end
end