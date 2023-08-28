classdef (Abstract) Shutter_Device < Device
    properties
        State
    end

    methods
        function obj = Shutter_Device(Initializer)
            obj@Device(Initializer);
        end

        function set.State(obj, val)
            obj.setshutterstate(val);
            obj.State = val;
        end
    end
    methods (Abstract)
        setshutterstate(obj, val);
    end
end
