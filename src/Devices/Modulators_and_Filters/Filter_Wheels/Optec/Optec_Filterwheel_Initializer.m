classdef Optec_Filterwheel_Initializer < Filter_Wheel_Initializer
    properties
        NET_DLL string
    end
    methods
        function obj = Optec_Filterwheel_Initializer()
            obj@Filter_Wheel_Initializer();
        end
    end
end
