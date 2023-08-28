classdef GH_AOTF_Controller_Initializer < Device_Initializer
    properties
        NUMCHANNELS uint8
        COMPORT string
        Power_calibration_curve double
        initialize_on_startup logical %flag specifies whether device should be initialized to state specified by following properties upon device creation.
        ChannelStates string
        ChannelFrequencies double
        ChannelPhases double
        ChannelPow double
    end
    methods
        function obj = GH_AOTF_Controller_Initializer()
            obj@Device_Initializer();
        end
    end
end
