classdef (Abstract) Filter_Wheel < Device
    properties
        filterlist string
        active_filter;
        active_filter_index;
    end

    methods
        function obj = Filter_Wheel(Initializer)
            obj@Device(Initializer);
            obj.filterlist = strjoin(obj.Initializer.filterlist, ',');
            obj.filterlist = strsplit(obj.filterlist, ',');
        end

        function set.active_filter(obj, filter)
            Set(obj, filter);
            obj.active_filter = filter;

        end

        function active_filter = get.active_filter(obj)
            active_filter = obj.filterlist(Get(obj));
        end

        function active_filter_index = get.active_filter_index(obj)
            active_filter_index = Get(obj);
        end
    end

    methods (Abstract) %must be implemented by subclass
        Set(obj, filter);
        Get(obj);
    end
end
