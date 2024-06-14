classdef RAS_SLM_LUT_Data < handle
    properties
        Phase_Maps = Phase_Map.empty
        wavelengths
        LUT_Mat
    end

    methods
        function obj = RAS_SLM_LUT_Data(wavelengths)
            obj.wavelengths = wavelengths;
        end

        function Append_Mean_Trace(obj, region, wavelength, gray_val, PD_mean)
            wavelength_index = obj.index_from_wavelength(wavelength);
            if numel(obj.Phase_Maps) < wavelength_index
                obj.Phase_Maps(wavelength_index) = Phase_Map();
            end
            obj.Phase_Maps(wavelength_index).append_point(region, gray_val, mean(PD_mean(:)));
        end

        function Construct_LUT_Mat(obj)
            obj.LUT_Mat = zeros(numel(obj.wavelengths), 256);
            for i = 1:numel(obj.wavelengths)
                obj.LUT_Mat(i, :) = obj.Phase_Maps(i).get_lut();
            end
        end

        function Save_LUT_Files(obj)
            for i = 1:numel(obj.wavelengths)
                fid = fopen(fullfile(obj.target_folder, strcat(num2str(obj.wavelengths(i)), '-LUT.txt')), 'w');
                for j = 0:255
                    fprintf(fid, '%d \s %d \n', int(j), int(round(obj.LUT_Mat(i, j+1))));
                end
                fclose(fid);
            end
        end

        function wavelength_index = index_from_wavelength(obj, wavelength)
            wavelength_index = find(obj.wavelengths == wavelength);
            if numel(wavelength_index) ~= 1
                error('Wavelength not in specified wavelengths vector')
            end
        end

    end
end
