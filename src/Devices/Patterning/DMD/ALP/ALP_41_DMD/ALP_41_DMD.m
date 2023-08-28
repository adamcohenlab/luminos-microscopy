% Since there is no matlab driver for ALP 4.1, we write C++ code to
% communicate with the DMD.

classdef ALP_41_DMD < DMD
    properties
        mexPointer;
        initialized
    end
    methods
        function Wait_Until_Done(obj)
            %Can be implemented with later release. For now, return
            %immediately.
        end
    end

    methods
        function obj = ALP_41_DMD(Initializer)
            obj@DMD(Initializer);
            obj.Startup();
            [dim1, dim2] = DMD_MEX('Get_Dimensions', obj.mexPointer);
            obj.Dimensions(1) = dim1;
            obj.Dimensions(2) = dim2;
            obj.calpoints = ceil(obj.Dimensions.*obj.frac_calpoints);
        end

        function Startup(obj)
            obj.mexPointer = DMD_MEX('new');
            obj.initialized = true;
        end

        function Write_Static(obj)
            obj.Target = obj.Target > .5; % The < or > defines whether this is inverted or not
            obj.Target = [obj.Target(1:1080, 1:1080), zeros(1080, 840)];
            finimage = uint8(obj.Target*128)';
            DMD_MEX('Project_Image', obj.mexPointer, finimage);
        end

        function Write_White(obj)
            obj.Target = ones(size(obj.Target));
            DMD_MEX('Project_White', obj.mexPointer);
        end

        function Write_Black(obj)
            obj.Target = ones(size(obj.Target));
            DMD_MEX('Project_Black', obj.mexPointer);
        end

        function Write_Checkerboard(obj)
            DMD_MEX('Project_Checkerboard', obj.mexPointer); %Only for Debug! Target Property not updated correctly.
        end

        function Write_Stack(obj)
            error('Not Implemented');
        end

        function Write_Video(obj)
            error('Not Implemented');
        end

        function delete(obj)
            if obj.initialized
                DMD_MEX('delete', obj.mexPointer);
                obj.initialized = false;
            end
        end

    end
end
