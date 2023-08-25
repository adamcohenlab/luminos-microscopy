classdef Laser_Device_Initializer < Device_Initializer
    properties
        maxPower double
        Wavelength double
    end
    methods
        function obj = Laser_Device_Initializer()
            obj@Device_Initializer();
        end
    end
end
