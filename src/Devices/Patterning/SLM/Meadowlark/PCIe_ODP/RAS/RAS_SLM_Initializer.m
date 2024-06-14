classdef RAS_SLM_Initializer < Meadowlark_PCIe_SLM_ODP_Initializer
    properties
        LUT_Stack
    end
    methods
        function obj = RAS_SLM_Initializer()
            obj@Meadowlark_PCIe_SLM_ODP_Initializer();
        end
    end
end
