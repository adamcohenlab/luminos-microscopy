classdef NI_DAQ_Shutter < Shutter_Device
    properties (Transient)
        DO_Channel DQ_DO_On_Demand
    end
    properties
        port string
    end
    methods
        function obj = NI_DAQ_Shutter(Initializer)
            obj@Shutter_Device(Initializer);
            obj.DO_Channel = DQ_DO_On_Demand(0, obj.Initializer.port);
        end

        function setshutterstate(obj, val)
            obj.DO_Channel.OD_Write(val);
        end
    end
end
