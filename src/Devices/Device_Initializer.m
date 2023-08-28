classdef Device_Initializer < handle & matlab.mixin.SetGetExactNames & matlab.mixin.Heterogeneous
    properties
        name string
        deviceType string
        Prop_Allowed_Vals = [] % not yet implemented
    end

    methods
        function obj = Device_Initializer()
            obj.deviceType = erase(class(obj), '_Initializer');
        end

        function device = Construct_Device(obj)
            device = feval(obj.deviceType, obj);
        end

    end

end
