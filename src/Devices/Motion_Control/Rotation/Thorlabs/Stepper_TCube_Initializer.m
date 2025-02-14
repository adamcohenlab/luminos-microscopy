classdef Stepper_TCube_Initializer < Motion_Controller_Initializer
    properties
        serialnumber
    end
    methods
        function obj = Stepper_TCube_Initializer()
            obj@Motion_Controller_Initializer();
        end
    end
end
