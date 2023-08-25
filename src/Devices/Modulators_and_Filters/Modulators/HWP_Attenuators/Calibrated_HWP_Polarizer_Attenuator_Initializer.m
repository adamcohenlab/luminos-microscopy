classdef Calibrated_HWP_Polarizer_Attenuator_Initializer < HWP_Polarizer_Attenuator_Initializer
    properties
        caldata Attenuator_Calibration_Data
    end
    methods
        function obj = Calibrated_HWP_Polarizer_Attenuator_Initializer()
            obj@HWP_Polarizer_Attenuator_Initializer();
        end
    end
end
