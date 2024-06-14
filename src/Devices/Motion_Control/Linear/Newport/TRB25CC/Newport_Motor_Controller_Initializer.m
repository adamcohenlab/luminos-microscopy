classdef Newport_Motor_Controller_Initializer < Linear_Controller_Initializer
    properties
        COMPORT string
        coarseStepSizeInit
        fineStepSizeInit
        zStageFlag 

    end
    methods
        function obj = Newport_Motor_Controller_Initializer()
            obj@Linear_Controller_Initializer();
        end
    end
end
