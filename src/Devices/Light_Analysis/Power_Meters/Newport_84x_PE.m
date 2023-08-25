classdef Newport_84x_PE < Device
    %Controller for newport high energy power meter
    properties
        %         range
        %         mean_power
        current_wavelength
        last_data = [];
        Hot_Pluggable = 1;
    end
    properties (Transient)
        dev
        COMPORT string
    end

    methods
        function obj = Newport_84x_PE(Initializer)
            obj@Device(Initializer);
            obj.COMPORT = Initializer.COMPORT;
            if Initializer.Hot_Pluggable == 0
                obj.Connect_to_Meter();
            end
        end

        function Connect_to_Meter(obj)
            obj.dev = serialport(obj.COMPORT, 115200, 'Timeout', obj.port_timeout);
            pause(.1);
            obj.Set_Autoscale();
        end

        function response = Set_Wavelength(obj, wavelength)
            obj.dev.writeline(char(strcat('*SWA', {' '}, num2str(round(wavelength)))));
            response = obj.dev.readline();
            obj.current_wavelength = wavelength;
        end

        function data = Read_Data(obj)
            obj.dev.writeline('*CVU');
            response = obj.dev.readline();
            split = strsplit(response, ':');
            data = str2double(split(2));
            obj.last_data = data;
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
