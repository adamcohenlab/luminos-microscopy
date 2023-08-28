classdef Filter_Wheel_Initializer < Device_Initializer
    properties
        filterlist string
    end
    methods
        function obj = Filter_Wheel_Initializer()
            obj@Device_Initializer();
        end
    end
end
