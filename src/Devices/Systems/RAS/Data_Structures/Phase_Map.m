classdef Phase_Map < handle
    properties
        map(:, 256) double
        active_index
    end

    methods
        function obj = Phase_Map(regions)
            obj.active_index = 0;
            obj.map = zeros(regions, 256);
        end
        function append_point(obj, region, gray_val, datapoint)
            obj.map(region, gray_val+1) = datapoint;
        end

        function append_full_map(obj, region, map)
            obj.map(region, :) = map;
        end

        function LUT = get_lut(obj)
            renormalized_map = (obj.map - min(obj.map));
            renormalized_map = renormalized_map * 255 / max(renormalized_map);
            fit_out = fit(0:255, renormalized_map, 'A*cos(f*x)+C');
            LUT = acos((0:255 - fit_out.C)/fit_out.A) / fit_out.f;
        end
    end
end
