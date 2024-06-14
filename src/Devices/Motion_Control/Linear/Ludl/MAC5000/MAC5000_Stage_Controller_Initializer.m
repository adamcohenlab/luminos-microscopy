classdef MAC5000_Stage_Controller_Initializer < Linear_Controller_Initializer
    properties
        COMPORT string
        microstep_size
        zStageFlag
    end
    methods
        function obj = MAC5000_Stage_Controller_Initializer()
            obj@Linear_Controller_Initializer();
        end
    end
end
