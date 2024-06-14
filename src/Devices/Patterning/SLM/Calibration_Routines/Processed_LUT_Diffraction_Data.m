classdef Processed_LUT_Diffraction_Data < handle
    properties
        Raw_Data RAS_SLM_LUT_Data
        wavelengths
        LUTs = WL_LUT.empty;
    end

    methods
        function obj = Processed_LUT_Diffraction_Data(LUT_Data)
            obj.Raw_Data = LUT_Data;
        end

        function Calculate_Phases(obj, xoffset)
            for i = 1:numel(obj.Raw_Data.Phase_Maps)
                phase_gray = obj.Diff_Data_to_Phase(obj.Raw_Data.Phase_Maps(i).map, xoffset);
                obj.LUTs(i) = WL_LUT(obj.Raw_Data.wavelengths(i), phase_gray, xoffset);
            end
        end

        function Calculate_Polynomials(obj)
            for i = 1:numel(obj.Raw_Data.Phase_Maps)
                obj.LUTs(i).Fit_Polynomial();
            end
        end

        function [phase_vec] = Diff_Data_to_Phase(obj, Diffraction_Data_Raw, xoffset)
            Diffraction_Data = smoothdata(Diffraction_Data_Raw, 'loess', 5);
            Diffraction_Data = Diffraction_Data(xoffset:end);
            bg_sub_diff_data = Diffraction_Data - min(Diffraction_Data);
            [mval, mindex] = max(bg_sub_diff_data);
            norm_diff_data = bg_sub_diff_data / mval;
            phase_vec = zeros(size(norm_diff_data));
            phase_vec(1:mindex) = 2 * asin(sqrt(norm_diff_data(1:mindex)));
            phase_vec(mindex+1:end) = 2 * pi - 2 * asin(sqrt(norm_diff_data(mindex+1:end)));
        end
    end
end
