classdef Initializer_Storage < handle
    properties
        devices = Device_Initializer.empty
    end
    methods
        function obj = Initializer_Storage()
        end
        function Add_Initializer(obj, Initializer)
            arguments
                obj
                Initializer Device_Initializer
            end
            obj.devices(end+1) = Initializer;
        end

        function Initializer = Get_Initializer(obj, deviceType)
            if any(strcmp({obj.devices.deviceType}, deviceType))
                Initializer = {obj.devices(strcmp({obj.devices.deviceType}, deviceType))};
            end
        end

        function devices = Construct_Devices(obj, deviceType)
            j = 1;

            for i = 1:numel(obj.Devices)
                if any(strcmp(deviceType, superclasses(obj.devices(i).deviceType)) | strcmp(deviceType, obj.devices(i).deviceType))
                    devices(j) = obj.devices(i).Construct_Device();
                    j = j + 1;
                end
            end
            if ~exist('Devices', 'var')
                devices = Placeholder.empty();
            end
        end
    end
end
