classdef NI_DAQ_Modulator < Modulator_Device
    properties (Transient)
        AO_OD DQ_AO_On_Demand
    end
    properties
        port string
    end

    methods
        function obj = NI_DAQ_Modulator(Initializer)
            obj@Modulator_Device(Initializer);
            obj.AO_OD = DQ_AO_On_Demand(0, obj.Initializer.port, 'max', obj.max, 'min', obj.min);
            obj.level = 0;
        end
        function setmodulatorlevel(obj, value)
            if ~isempty(obj.AO_OD)
                obj.AO_OD.data = value;
            end
        end
    end
end
