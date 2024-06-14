classdef Scientifica_Stage_Controller_Initializer < Linear_Controller_Initializer
    properties
        COMPORT string
        %		x
        %		y
        %		z
        microstep_size
        driver string
        zStageFlag
    end
    methods
        function obj = Scientifica_Stage_Controller_Initializer()
            obj@Linear_Controller_Initializer();
        end
    end
end
