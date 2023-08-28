classdef DQ_Channel < handle
    properties
        name
        phys_channel
        min double
        max double
    end
    properties (SetObservable)
        data(1, :) double
    end
    methods
        function obj = DQ_Channel(options)
            arguments
                options.name = '';
                options.phys_channel = '';
                options.data = [];
                options.min = -10;
                options.max = 10;
            end
            obj.name = options.name;
            obj.phys_channel = options.phys_channel;
            obj.data = options.data;
            obj.min = options.min;
            obj.max = options.max;
        end
    end
end
