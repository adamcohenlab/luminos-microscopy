classdef Trap_Device_Initializer < Patterning_Device_Initializer
    properties
        galvox_phys_channel(1, :) char
        galvoy_phys_channel(1, :) char
        calvoltage(4, 2) double
        x_lim(1, 2) double
        y_lim(1, 2) double
        minstep double
        volts_per_pixel double
    end
    methods
        function obj = Trap_Device_Initializer()
            obj@Patterning_Device_Initializer();
        end
    end
end
