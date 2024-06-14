classdef SLM_Device_Initializer < Patterning_Device_Initializer
    properties
        TiltX double
        TiltY double
        AstX double
        AstY double
        Defocus double
        ComaX double
        ComaY double
        Spherical double

        Beam_Waist double
    end
    methods
        function obj = SLM_Device_Initializer()
            obj@Patterning_Device_Initializer();
        end
    end
end
