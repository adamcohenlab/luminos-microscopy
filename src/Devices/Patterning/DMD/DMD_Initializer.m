classdef DMD_Initializer < Patterning_Device_Initializer
    properties
        trigger_channel % Optional property to hold the trigger channel
    end
    methods
        function obj = DMD_Initializer(trigger_channel)
            obj@Patterning_Device_Initializer();
            if nargin > 0
                obj.trigger_channel = trigger_channel;
            end
        end
    end
end
