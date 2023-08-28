classdef ASI_Filterwheel_Initializer < Filter_Wheel_Initializer
    properties
        COMPORT string
    end
    methods
        function obj = ASI_Filterwheel_Initializer()
            obj@Filter_Wheel_Initializer();
        end
    end
end
