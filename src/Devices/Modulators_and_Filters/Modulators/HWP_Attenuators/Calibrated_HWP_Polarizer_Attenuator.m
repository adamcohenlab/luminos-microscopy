classdef Calibrated_HWP_Polarizer_Attenuator < HWP_Polarizer_Attenuator
    properties (Transient)
        calfile
    end
    properties
        caldata Attenuator_Calibration_Data
        power
        wavelength
        power_at_max
    end

    methods
        function obj = Calibrated_HWP_Polarizer_Attenuator(Initializer)
            obj@HWP_Polarizer_Attenuator(Initializer);
            obj.caldata = obj.Initializer.caldata;
        end

        function SetPower(obj, power, wavelength)
            obj.wavelength = wavelength;
            obj.power = power;
            set_angle = obj.caldata.HWP_angle(wavelength, power);
            if ~isnan(set_angle)
                obj.rotation_motor.moveto(set_angle);
            else
                warning("No attenuator calibration data for this range. Caution as power may be outside of specifications");
            end
        end
    end
end
