classdef Spinning_Disk_Initializer < Device_Initializer
    properties
        COMPORT
    end
    methods
        function obj = Spinning_Disk_Initializer()
            obj@Device_Initializer();
        end
    end
end