classdef Newport_84x_PE < Power_Meter
    %Controller for newport high energy power meter
    properties
        Hot_Pluggable = 1;
        darkOffsetPower;
        detector_info;
    end
    properties (Transient)
        dev
        COMPORT string
    end

    methods
        function obj = Newport_84x_PE(Initializer)
            obj@Power_Meter(Initializer);
            obj.COMPORT = Initializer.COMPORT;
            if Initializer.Hot_Pluggable == 0 || obj.autoconnect
                obj.connect();
            end
        end

        function connect(obj)
            obj.dev = serialport(obj.COMPORT, 115200, 'Timeout', obj.port_timeout);
            obj.isConnected = true;
            pause(.1);
            obj.Set_Autoscale();
            obj.sensorInfo()
        end

        function info = sensorInfo(obj)
            info = {};
            obj.dev.writeline('*HEA');
            info{1} = obj.dev.readline();
            obj.dev.writeline('*STA');
            info{2} = obj.dev.readline();
            info{3} = obj.dev.readline();
            info{4} = obj.dev.readline();
            obj.detector_info = info;
        end

        function response = setWavelength(obj, wavelength)
            obj.dev.writeline(char(strcat('*SWA', {' '}, num2str(round(wavelength)))));
            response = obj.dev.readline();
            obj.wavelength = wavelength;
        end

        function data = readData(obj)
            obj.dev.writeline('*CVU');
            response = obj.dev.readline();
            split = strsplit(response, ':');
            data = str2double(split(2));
            obj.meterPowerReading = data;
            obj.meterPowerUnit = "W";
        end
        function response = darkAdjust(obj,disable)
            arguments
                obj Newport_84x_PE
                disable logical = false;
            end
            %DARKADJUST Initiate the Zero value measurement.
            %   Usage: obj.darkAdjust;
            %   Start the measurement of Zero value.
            obj.darkOffsetPower = obj.readData();
            if disable
                obj.dev.writeline('*EOA 0');
            end
            obj.dev.writeline('*EOA 1');
            response = obj.dev.readline();
        end
        function response = Set_Autoscale(obj)
            obj.dev.writeline('*SSA Auto');
            response = obj.dev.readline();
        end
        function response = Set_Scale(obj, arg)
            obj.dev.writeline(char(strcat('*SSA', {' '}, arg)));
            response = obj.dev.readline();
        end
        function response = Set_Mode(obj, mode)
            obj.dev.writeline(char(strcat('*SDU', {' '}, num2str(mode))));
            response = obj.dev.readline();
        end
        function response = Enable_Statistics(obj, mode)
            obj.dev.writeline('*ESU');
            response = obj.dev.readline();
        end
    end
end
