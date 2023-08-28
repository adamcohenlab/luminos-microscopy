classdef Thorlabs_PM400_Initializer < Device_Initializer
    properties
        autoconnect
    end
    methods
        function obj = Thorlabs_PM400_Initializer()
            obj@Device_Initializer();
        end
    end
end
