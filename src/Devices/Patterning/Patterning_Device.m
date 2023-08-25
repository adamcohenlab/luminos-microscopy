classdef (Abstract) Patterning_Device < Device
    properties
        %Transform Calibration Information
        calpoints
        frac_calpoints double
        calPS double
        calthresh double
        refimagefile
        refimage CL_RefImage
    end
    properties (Transient)
        tax matlab.ui.control.UIAxes;
        debug_mode
        append_mode
        Dimensions(1, 2) double
        demo_ax matlab.graphics.axis.Axes;
        snapreference
        stack_mode
        im_stack_file
        SDK_Loaded = false;
        I
        Alignment_Pattern_Stack = Alignment_Pattern.empty;
        additionalConfigData AdditionalConfigData; % for storing calibration data
    end
    properties (SetObservable = true)
        testimage
        pattern_stack
        Target
        roi_stack Patterning_ROI_Stack
        smoothing
        tform % transform from camera to patterning device
    end
    methods
        function obj = Patterning_Device(Initializer)
            obj@Device(Initializer);
            obj.calthresh = 5;
            obj.debug_mode = obj.Initializer.debug_mode;
            obj.snapreference = false;
            obj.stack_mode = false;
            obj.smoothing = 1;
            obj.roi_stack = Patterning_ROI_Stack();
            obj.Alignment_Pattern_Stack = obj.Initializer.Alignment_Pattern_Stack;
            
            % construct calibration data object
            obj.additionalConfigData = AdditionalConfigData(obj);
            obj.Load_Inits();
        end
        
        % load data from initializer into object
        function Load_Inits(obj)
            initTform = obj.additionalConfigData.get("tform");
            
            % set tform as identity
            if (isempty(initTform))
                initTform = affine2d(eye(3));
                obj.additionalConfigData.set("tform", initTform);
            end
            
            if isa(initTform, 'affine2d')
                % assign tform to object
                obj.tform = initTform;
            else
                error("tform must be an affine2d object");
            end
            
            % grab other props from the initializer
            obj.frac_calpoints = obj.Initializer.frac_calpoints;
            obj.calPS = obj.Initializer.calPS;
        end
        
        function setPatterningROI(obj, rmask, options)
            arguments
                obj
                rmask
                options.write_when_complete logical = true
            end
            transform = obj.tform;
            Rfixed = imref2d([obj.Dimensions(2), obj.Dimensions(1)]);
            
            % upsample to 2048 x 2048 or the size of the reference image
            if ~isempty(obj.refimage)
                newSize = size(obj.refimage.img);
            else
                newSize = [2048, 2048];
            end
            
            rmask = imresize(rmask, newSize);
            
            % apply transformation from image space to patterning device space
            tmask = imwarp(rmask, transform, 'OutputView', Rfixed);
            if obj.smoothing == 0
                obj.Target = tmask;
            else
                obj.Target = imgaussfilt(double(tmask), obj.smoothing);
            end
            if options.write_when_complete
                obj.Write_Static();
            end
        end
        
        % load stack of pattersn from a file provided in im_stack_file
        function Load_Stack_From_File(obj)
            if ~isempty(obj.im_stack_file)
                stackdata = load(obj.im_stack_file);
                obj.pattern_stack = stackdata.framestack;
            end
        end
        
        % load a reference image that is used for metadata about the camera / other acquiring device
        % this function is typically called by the GUI
        function Load_Ref_Im_JS(obj, filename)
            obj.refimagefile = strrep(filename, '.png', '.mat'); %pass in the full path to the .mat file in the "snaps" folder
            lsnap = load(obj.refimagefile);
            obj.refimage = lsnap.snap;
        end
        
        % get the dimensions of the reference image
        function dims = ref_im_dims(obj)
            if ~isempty(obj.refimage)
                dims = size(obj.refimage.img);
            else
                error("No reference image loaded. Cannot calculate dimensions");
            end
        end
        
        % NOTE: This function might be unused.
        function Load_Ref_Im(obj,options)
            % setup for displaying the image
            if ~isvalid(obj.tax)
                figure
                tax = gca;
                obj.tax = tax;
            end
            
            % refimage is the CL_RefImage object. testimage is the thing that gets displayed.
            if isempty(obj.refimagefile)
                warning("No image selected. Please select image file.");
                return
            end
            if contains(obj.refimagefile, '.tiff')
                obj.testimage = double(imread(obj.refimagefile));
                obj.refimage = CL_RefImage();
                obj.tax.XLim = [0, size(obj.testimage, 2)];
                obj.tax.YLim = [0, size(obj.testimage, 1)];
                obj.I = imagesc(obj.tax, obj.testimage);
            elseif contains(obj.refimagefile, '.mat')
                obj.testimage = double(imread(strrep(obj.refimagefile, '.mat', '.tiff')));
                obj.I = imagesc(obj.tax, obj.testimage);
                lsnap = load(obj.refimagefile);
                obj.refimage = lsnap.snap;
                obj.I.XData = obj.refimage.xdata;
                obj.I.YData = obj.refimage.ydata;
                axis(obj.tax, 'tight')
            end
            drawnow
        end
        
        function calculateCalibrationTransform(obj, pts)
            fixed = obj.GenTargetFromSpots(obj.calpoints, obj.Dimensions, 10);
            display(pts);
            tic;
            t_est = estimateGeometricTransform(pts, obj.calpoints, 'affine');
            
            % print the time it took to calculate the transform
            fprintf("Calibration transform calculated in %f seconds\n", toc);
            
            tform_out = obj.RefT(double(fixed), obj.refimage.img, 5, t_est, obj.refimage.ref2d);
            obj.tform = tform_out;
            if obj.debug_mode == 1
                imagesc(obj.demo_ax(2), obj.Target);
            end
            
            % update the tform in the additional config data
            obj.additionalConfigData.set("tform", obj.tform);
        end
        
    end
    
    methods (Static, Hidden = true)
        function finaltform = RefT(fixed, snapimage, smoothing, manualestimate, MovingRef)
            fixed = double(fixed);
            fixed = imgaussfilt(fixed, smoothing);
            Rfixed = imref2d(size(fixed));
            [optimizer, metric] = imregconfig('multimodal');
            optimizer.InitialRadius = optimizer.InitialRadius / 10;
            optimizer.MaximumIterations = 500;
            moving = imgaussfilt(snapimage, smoothing);
            finaltform = imregtform(moving, MovingRef, fixed, Rfixed, ...
                'affine', optimizer, metric, 'InitialTransformation', manualestimate);
            movingRegistered = imwarp(moving, MovingRef, finaltform, 'OutputView', Rfixed);
            figure
            subplot(1, 2, 1)
            imagesc(fixed./max(fixed(:)));
            subplot(1, 2, 2)
            imagesc(5*movingRegistered./max(movingRegistered(:)))
        end
        
    end
end
