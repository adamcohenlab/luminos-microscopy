classdef (Abstract) Linear1D_Controller < Motion_Controller
    % mainly for controlling the z-stage Newport motor
    
    properties (Abstract)
        pos struct % fine and coarse stepsize, current position in mm
    end
    
    methods
        function obj = Linear1D_Controller(Initializers)
            obj@Motion_Controller(Initializers)
        end
    end
    
    methods (Abstract) % Must be implemented in subclass
        success = Move_To_Position(obj, position)
    end
end
