classdef (Abstract) Linear_Controller < Motion_Controller
    % mainly for controlling the stage
    
    properties (Abstract)
        pos struct % current position in microns {x,y,z} (z optional)
    end
    
    methods
        function obj = Linear_Controller(Initializers)
            obj@Motion_Controller(Initializers)
        end
    end
    
    methods (Abstract) % Must be implemented in subclass
        success = Move_To_Position(obj, position) % position is a 1x3 vector of micron coordinates
    end
end
