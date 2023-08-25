classdef Voltage_Shutter < Shutter_Device
    properties (Transient)
        AO_OD DQ_AO_On_Demand
    end

    properties
        port string
        offVoltage double
        onVoltage double
    end

    methods
        function obj = Voltage_Shutter(Initializer)
            obj@Shutter_Device(Initializer);
            obj.AO_OD = DQ_AO_On_Demand(0, obj.Initializer.port, 'max', obj.onVoltage, 'min', obj.offVoltage);
        end

        function setshutterstate(obj, val)
            if val == 1
                obj.AO_OD.OD_Write(obj.Initializer.onVoltage);
            else
                obj.AO_OD.OD_Write(obj.Initializer.offVoltage);
            end
        end
    end
end
