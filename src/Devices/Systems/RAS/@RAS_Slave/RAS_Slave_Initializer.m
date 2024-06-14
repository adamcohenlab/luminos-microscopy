classdef RAS_Slave_Initializer < Device_System_Initializer
    properties
        master_ip_address
        master_tcpip_port
        waveform
    end

    methods
        function obj = RAS_Slave_Initializer()
            obj@Device_System_Initializer();
        end

    end
end
