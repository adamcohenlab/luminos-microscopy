classdef Camera_Initializer < Device_Initializer
    properties
        trigger string % trigger line to start the acqusition e.g. "Dev1/port0/line3", "Dev1/PFI2", "Dev1/CTR0" 
        clock string
        hsync_rate double
        vsync string
        daqTrigCounter = "" % Optional parameter if using the daq as the frame trigger (e.g. "Dev1/Ctr0")
        type double
        rdrivemode
        cam_id
        virtualSensorSize
        microns_per_pixel = 6.5; % Default pixel size, true for Hamamatsu Orca Flash, Fusion and Teledyne Kinetix
        slave = false; % This must to be true if this camera is triggered off a CTR using a other camera's clock output.
    end
    methods
        function obj = Camera_Initializer()
            obj@Device_Initializer();
        end
    end
end
