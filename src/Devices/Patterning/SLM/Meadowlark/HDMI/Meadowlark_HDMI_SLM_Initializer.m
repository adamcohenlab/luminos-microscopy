classdef Meadowlark_HDMI_SLM_Initializer < Meadowlark_SLM_Device_Initializer
    properties
        SDK_Filepath string
    end
    methods
        function obj = Meadowlark_HDMI_SLM_Initializer()
            obj@Meadowlark_SLM_Device_Initializer();
        end
    end
end
