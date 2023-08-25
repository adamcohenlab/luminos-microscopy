classdef ASI_Filterwheel < Filter_Wheel
    properties (Transient)
        SPORT %serial communication
        COMPORT string
    end

    methods
        function obj = ASI_Filterwheel(Initializer)
            obj@Filter_Wheel(Initializer);
            obj.COMPORT = obj.Initializer.COMPORT;
            obj.SPORT = serialport(obj.COMPORT, 115200, 'Timeout', obj.port_timeout); %Matlab defaults to appropriate Parity etc.
            configureTerminator(obj.SPORT, "CR"); %Set the terminator to carriage return
        end

        function obj = Set(obj, filtername)
            x = find(strcmp(obj.filterlist, filtername));
            try
                x = x(1); %necessary in case there are duplicate filters ("empty")
            catch
                warning("Filter wheel not found in config file");
            end
            message = strcat("3FMP ", num2str(x-1)); %ASIs are 0-indexed
            writeline(obj.SPORT, message);
        end

        function filter_index = Get(obj)
            flush(obj.SPORT);
            writeline(obj.SPORT, "3FMP");
            out = strsplit(strip(readline(obj.SPORT)));
            filter_index = str2double(out(end)) + 1; %since ASI starts at 0, add 1 to produce 1-indexed result
        end
    end
end
