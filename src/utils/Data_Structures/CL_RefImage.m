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
        timestamp
    end

    methods
        function obj = CL_RefImage()
            obj.name = 'none';
            obj.type = 'none';
            if isMATLABReleaseOlderThan("R2022b")
                obj.tform = affine2d(eye(3)); %old pre-R2022b convention
            else
                obj.tform = affinetform2d(eye(3)); %new premultiply convention
            end
            obj.ref2d = imref2d();
        end

    end
end
