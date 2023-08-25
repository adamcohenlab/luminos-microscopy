classdef (Abstract) Motion_Controller < Device
    %Assign all motion controllers as a subclass of this class.
    properties
    end

    methods
        function obj = Motion_Controller(Initializers)
            obj@Device(Initializers)
        end
    end
end
