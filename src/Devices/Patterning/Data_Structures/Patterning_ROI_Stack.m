classdef Patterning_ROI_Stack < handle & matlab.mixin.SetGetExactNames
    properties
        roi_stack = images.roi.internal.AbstractPolygon.empty
        types(:, 1) string
        smoothing
        group_index
        reference_image
        user_data
    end

    methods
        function obj = Patterning_ROI_Stack()
        end
        function Add_ROI(obj, roi, type, group_index, options)
            arguments
                obj
                roi
                type
                group_index
                options.smoothing = -1;
            end
            obj.roi_stack(end+1) = roi;
            obj.types(end+1) = string(type);
            obj.smoothing(end+1) = options.smoothing;
            obj.group_index(end+1) = group_index;
        end
        function Clear_Stack(obj)
            if ~isempty(obj.roi_stack)
                for i = 1:numel(obj.roi_stack)
                    delete(obj.roi_stack(i));
                end
            end
            obj.roi_stack = images.roi.internal.AbstractPolygon.empty;
            obj.types = [];
        end
    end
end