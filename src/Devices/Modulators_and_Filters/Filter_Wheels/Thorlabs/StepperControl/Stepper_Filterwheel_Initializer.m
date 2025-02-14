classdef Stepper_Filterwheel_Initializer < Filter_Wheel_Initializer
    properties
        serialnumber
    end
    methods
        function obj = Stepper_Filterwheel_Initializer()
            obj@Filter_Wheel_Initializer();
        end
    end
end
