classdef Thorlabs_Filterwheel < Filter_Wheel
    properties (Transient)
        SPORT %serial communication
        COMPORT string
    end

    methods
        function obj = Thorlabs_Filterwheel(Initializer)
            obj@Filter_Wheel(Initializer);
            obj.COMPORT = obj.Initializer.COMPORT;
            obj.SPORT = serialport(obj.COMPORT, 115200, 'Timeout', obj.port_timeout); %Matlab defaults to appropriate Parity etc.
            configureTerminator(obj.SPORT, "CR"); %Set the terminator to carriage return
        end

        function Set(obj, value)
            x = find(strcmp(obj.filterlist, value));
            try
                x = x(1); %necessary in case there are duplicate filters ("empty")
            catch
                warning("Filter wheel not found in config file");
            end
            message = strcat("pos=", num2str(x));
            writeline(obj.SPORT, message);
        end

        function filter_index = Get(obj)
            flush(obj.SPORT);
            writeline(obj.SPORT, "pos?");
            readline(obj.SPORT); %Some Thorlabs FWs, at least, echo command, which should be ignored.
            filter_index = str2double(readline(obj.SPORT));
        end
    end
end
