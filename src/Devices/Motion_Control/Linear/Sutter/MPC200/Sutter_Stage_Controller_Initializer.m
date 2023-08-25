classdef Sutter_Stage_Controller_Initializer < Linear_Controller_Initializer
    properties
        COMPORT string
    end
    methods
        function obj = Sutter_Stage_Controller_Initializer()
            obj@Linear_Controller_Initializer();
        end
    end
end
