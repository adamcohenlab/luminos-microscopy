classdef Scanning_Device_Initializer < Patterning_Device_Initializer
    properties
        vbounds(1, 4) double
        timebase_source(1, :) char % clock port (if blank, use the DAQ internal clock)
        trigger_physport(1, :) char
        PMT_physport(1, :) char
        galvofbx_physport(1, :) char
        galvofby_physport(1, :) char
        galvox_physport(1, :) char
        galvoy_physport(1, :) char
        sync_counter(1, :) char % send a rising edge when each frame finishes
        sample_rate double
        DAQ_Vendor uint16
        feedback_scaling double
        galvos_only uint16
        volts_per_pixel(1,1) double
    end
    methods
        function obj = Scanning_Device_Initializer()
            obj@Patterning_Device_Initializer();
        end
    end
end
