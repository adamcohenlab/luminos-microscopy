classdef (Abstract) Modulator_Device < Device
    properties
        level
        min
        max
        iscalibrated
        calibration_curve
    end

    properties (SetAccess = private)
        raw_level
    end

    properties (Transient)
        calibration_meter = []
    end

    methods
        function obj = Modulator_Device(Initializer)
            obj@Device(Initializer);
            if ~isempty(Initializer.min)
                obj.min = Initializer.min;
            else
                obj.min = -10;
            end
            if ~isempty(Initializer.max)
                obj.max = Initializer.max;
            else
                obj.max = 10;
            end
        end

        function set.level(obj, value)
            obj.setmodulatorlevel_wcal(value);
            obj.level = value;
        end

        function raw_level = apply_calibration(obj, value) %Should be overloaded in subclasses for more complex calibrations
            if ((value > min(obj.calibration_curve(1, :))) && (value < max(obj.calibration_curve(2, :))))
                raw_level = maxima(obj.calibration_curve(1, :), obj.calibration_curve(2, :), value);
            else
                error('Requested Value Outside of Calibrated Range');
            end
        end

        function Run_Calibration(obj)
            if isempty(obj.calibration_meter)
                error('calibration_meter handle not attached to device')
            else
                curve = linspace(obj.min, obj.max, 1000);
                for i = 1:numel(curve)
                    obj.setmodulatorlevel(curve(i));
                    pause(.5)
                    obj.calibration_curve(1, i) = obj.meter.Read_Data();
                    obj.calibration_curve(2, i) = curve(i);
                end
            end
        end

        function setmodulatorlevel_wcal(obj, value)
            if obj.iscalibrated
                obj.raw_level = obj.apply_calibration(value);
            else
                obj.raw_level = value;
            end
            obj.setmodulatorlevel(obj.raw_level);
        end

    end
    methods (Abstract)
        setmodulatorlevel(obj, value);
    end
end
