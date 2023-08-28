classdef DAQ_Initializer < Device_Initializer
    properties
        alias_init string = "" % a comma separated string that looks like "port1,name1,port2,name2" etc.
        defaultClock string = "" % default clock port
        default_trigger string = "" % default trigger port
    end
    methods
        function obj = DAQ_Initializer()
            obj@Device_Initializer();
        end
    end
end
