classdef WL_LUT < handle
    properties
        wavelength
        phase_gray
        gray_xoffset
        LUT_Ref
        Bit_Depth
        poly
        numregions
        m_diff_data
    end

    methods
        function obj = WL_LUT(wavelength, diff_data, numregions)
            obj.wavelength = wavelength;
            for i = 1:numregions
                [obj.phase_gray{i}, obj.gray_xoffset(i)] = Diff_Data_to_Phase(diff_data(i, :));
            end
            obj.numregions = numregions;
            obj.Fit_LUT_Ref();
        end
        function Fit_LUT_Ref(obj)
            obj.LUT_Ref = zeros(obj.numregions, 256);
            for i = 1:obj.numregions
                numvec = numel(obj.phase_gray{i});
                obj.poly = polyfit(obj.phase_gray{i}*256/(2 * pi), (obj.gray_xoffset(i) - 1)+(0:numvec - 1), 4);
                obj.LUT_Ref(i, :) = uint8(round(polyval(obj.poly, 0:255)));
            end
        end
    end
end
