classdef HWP_Polarizer_Attenuator_Initializer < Device_Initializer
    properties
        fast_axis
        power_at_max
        motor_serialnumber string
        motor_type string
    end
    methods
        function obj = HWP_Polarizer_Attenuator_Initializer()
            obj@Device_Initializer();
        end
    end
end
