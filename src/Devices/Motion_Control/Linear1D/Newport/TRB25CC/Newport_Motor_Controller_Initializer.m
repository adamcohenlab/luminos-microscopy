classdef Newport_Motor_Controller_Initializer < Linear1D_Controller_Initializer
    properties
        COMPORT string
        coarseStepSizeInit
        fineStepSizeInit

    end
    methods
        function obj = Newport_Motor_Controller_Initializer()
            obj@Linear1D_Controller_Initializer();
        end
    end
end
