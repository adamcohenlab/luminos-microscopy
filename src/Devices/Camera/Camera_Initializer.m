classdef Camera_Initializer < Device_Initializer
    properties
        trigger string % trigger line to start the acqusition e.g. "Dev1/port0/line3"
        clock string
        hsync_rate double
        vsync string
        daqTrigCounter = "" % Optional parameter if using the daq as the frame trigger (e.g. "Dev1/Ctr0")
        type double
        rdrivemode
        cam_id
        virtualSensorSize
    end
    methods
        function obj = Camera_Initializer()
            obj@Device_Initializer();
        end
    end
end
