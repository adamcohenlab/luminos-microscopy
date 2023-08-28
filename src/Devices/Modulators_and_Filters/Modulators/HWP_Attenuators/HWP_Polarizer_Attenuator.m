classdef HWP_Polarizer_Attenuator < Device
    properties (Transient)
        rotation_motor Motion_Controller
        fast_axis
        motor_serialnumber string
        motor_type string
    end
    properties
        rel_power
    end

    methods
        function obj = HWP_Polarizer_Attenuator(Initializer)
            obj@Device(Initializer);
            obj.fast_axis = obj.Initializer.fast_axis;
            obj.motor_type = obj.Initializer.motor_type;
            obj.motor_serialnumber = obj.Initializer.motor_serialnumber;
            if strcmp(obj.motor_type, 'TCube')
                obj.rotation_motor = DCServo_TCube([], 'serialnumber', obj.motor_serialnumber);
            end
        end
        function Set(obj, relpower)
            offsetangle = acosd(sqrt(relpower));
            obj.rotation_motor.moveto(mod(offsetangle, 180)+obj.fast_axis); %mod180 so you never walk across max power point unintentionally.
            obj.rel_power = relpower;
        end
    end
end
