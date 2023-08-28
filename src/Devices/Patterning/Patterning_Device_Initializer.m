classdef Patterning_Device_Initializer < Device_Initializer
    properties
        tform
        frac_calpoints double
        calPS double
        debug_mode double
        Alignment_Pattern_Stack(:, :) double
    end
    methods
        function obj = Patterning_Device_Initializer()
            obj@Device_Initializer();
        end
    end
end
