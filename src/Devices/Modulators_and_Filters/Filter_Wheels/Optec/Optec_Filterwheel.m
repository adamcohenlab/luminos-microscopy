classdef Optec_Filterwheel < Filter_Wheel
    properties (Transient)
        NET_DLL string
        filter
    end

    methods
        function obj = Optec_Filterwheel(Initializer)
            obj@Filter_Wheel(Initializer);
            obj.NET_DLL = obj.Initializer.NET_DLL;
            asm = NET.addAssembly(obj.NET_DLL);
            import OptecHID_FilterWheelAPI.*
            wheels = OptecHID_FilterWheelAPI.FilterWheels;
            wheelslist = ToArray(wheels.FilterWheelList);
            obj.filter = wheelslist(1);
        end

        function obj = Set(obj, filtername)
            x = find(strcmp(obj.filterlist, filtername));
            try
                x = x(1); %necessary in case there are duplicate filters ("empty")
            catch
                warning("Filter wheel not found in config file");
            end
            obj.filter.CurrentPosition = x;
        end

        function filter_index = Get(obj)
            x = obj.filter.CurrentPosition;
            filter_index = x;
        end
    end
end
