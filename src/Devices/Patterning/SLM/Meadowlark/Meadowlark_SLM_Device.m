classdef (Abstract) Meadowlark_SLM_Device < SLM_Device
    properties (Transient)
        gpu_available
    end
    properties
        lut_file
        Coverglass_Voltage = 6.3 %Comment out for non BU
    end

    methods
        function obj = Meadowlark_SLM_Device(Initializer)
            obj@SLM_Device(Initializer);
            obj.lut_file = Initializer.lut_file;
        end
        function set.Coverglass_Voltage(obj, value)
            res = obj.SetCoverVoltage(value);
            if res
                obj.Coverglass_Voltage = value;
            end
        end
    end
    methods (Static)
        function res = SetCoverVoltage(volts)
            if volts > 6 && volts < 6.4
                try
                    x = calllib('Blink_C_wrapper', 'Set_SLMVCom', volts);
                catch
                    %display('SDK not yet loaded. Did not set voltage');
                    res = false;
                    return
                end
                if x == false
                    error('Coverglass Voltage Write Failed')
                else
                    res = true;
                end
            else
                warning('Did not adjust coverglass voltage. Requested value out of range')
                res = false;
            end
        end
    end
end
