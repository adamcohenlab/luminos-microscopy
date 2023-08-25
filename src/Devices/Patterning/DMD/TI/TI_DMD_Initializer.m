classdef TI_DMD_Initializer < DMD_Initializer
    properties
        Dimensions(1, 2) double
    end
    methods
        function obj = TI_DMD_Initializer()
            obj@DMD_Initializer();
        end
    end
end
