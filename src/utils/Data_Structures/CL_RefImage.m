classdef CL_RefImage < handle
    %Simple container for a referenced snap
    properties
        img
        xdata
        ydata
        type
        name
        tform
        ref2d
    end

    methods
        function obj = CL_RefImage()
            obj.name = 'none';
            obj.type = 'none';
            obj.tform = affine2d(eye(3));
            obj.ref2d = imref2d();
        end

    end
end
