classdef Rig_Initializer < Initializer_Storage
    properties
        rigname
        dataDirectory
        tabs
    end
    methods
        function obj = Rig_Initializer()
            obj@Initializer_Storage();
        end
    end
end