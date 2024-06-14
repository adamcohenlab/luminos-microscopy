classdef RAS_SLM_LUT_Stack < handle
    properties
        LUTs = WL_LUT.empty;
    end

    methods
        function obj = RAS_SLM_LUT_Stack()
        end

        function AddLUT(obj, LUT)
            wl_list = cell2mat({obj.LUTs.wavelength});
            if (any(wl_list == LUT.wavelength))
                error('LUT for specified wavelength already included in stack.');
            end
            obj.LUTs(end+1) = LUT;
        end

        function LUT = GetLUT(obj, wavelength)
            wl_list = cell2mat({obj.LUTs.wavelength});
            if ~any(wl_list == wavelength)
                warning('requested wavelength not present in SLM LUT stack');
                LUT = [];
            else
                LUT = obj.LUTs(wl_list == wavelength);
            end
        end
    end
end
