classdef (Abstract) Patterning_Device < Device
    properties
        %Transform Calibration Information
        calpoints
        frac_calpoints double
        calPS double
        calthresh double
        refimagefile
        refimage CL_RefImage
        allOnImage %Image representing patterning device fully on.
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
        APRILTAGFAMILY = "tagCustom48h12";
    end
    properties (SetObservable = true)
        testimage
        pattern_stack
        Target
        roi_stack Patterning_ROI_Stack
        smoothing
        tform % transform from camera to patterning device. Should be affinetform2d object if Matlab >R2022b.
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
                if isMATLABReleaseOlderThan("R2022b")
                    initTform = affine2d(eye(3));
                else
                    initTform = affinetform2d(eye(3));
                end
                obj.additionalConfigData.set("tform", initTform);
            end
            
            if isa(initTform, 'affine2d') %for backwards compatibility in old init files, convert to new premultiply convention
                if isMATLABReleaseOlderThan("R2022b")
                else
                    T = initTform.T;
                    A = T';
                    initTform = affinetform2d(A);
                end
            end
            obj.tform = initTform;
            
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
        
        
        function calculateCalibrationTransform(obj, pts,flag)
            arguments
                obj Patterning_Device
                pts = [];
                flag = "";
            end
            if strcmp(flag,"AprilTag")
                obj.Read_Calibration_Pattern();
                return;
            end
            fixed = obj.GenTargetFromSpots(obj.calpoints, obj.Dimensions, 10);
            
            %Determine what type of transform is appropriate. Could be
            %expanded. Minimum 4 pairs for projective.
            if size(obj.calpoints,1) >= 4
                transformType = "projective";
            else
                transformType = "affine";
            end
            
            if isMATLABReleaseOlderThan("R2022b")
                t_est = estimateGeometricTransform(pts, obj.calpoints, transformType); % Old pre-R2022b convention
            else
                t_est = estgeotform2d(pts, obj.calpoints, transformType); % New premultiply convention
            end
            
            Rfixed = imref2d(size(fixed));
            moving = imadjust(mat2gray(obj.refimage.img));
            movingRegistered = imwarp(moving, t_est, 'OutputView', Rfixed);
            figure
            subplot(1, 3, 1)
            imagesc(fixed./max(fixed(:)));
            subplot(1, 3, 2)
            imagesc(movingRegistered);
            sgtitle("Calibration Results");
            subplot(1, 3, 3)
            imshowpair(fixed,movingRegistered);
            
            % tic
            % fprintf("Performing image alignment");
            % tform_out = obj.RefT(mat2gray(fixed), moving, 5, t_est, obj.refimage.ref2d);
            % fprintf("Calibration transform estimated in %f seconds\n", toc);
            obj.tform = t_est;
            %Unnecessary. imregtform (in RefT) automatically spits out the
            %appropriate sort of transform depending on the version.
            % if isMATLABReleaseOlderThan("R2022b")
            %     tform_obj_out = affine2d(tform_out.tdata.T);
            % else
            %     tform_obj_out = affinetform2d(tform_out.tdata.T);
            % end
            % obj.tform = tform_obj_out;
            if obj.debug_mode == 1
                imagesc(obj.demo_ax(2), obj.Target);
            end
            
            % Update the tform in the additional config data regardless of path
            obj.additionalConfigData.set("tform", obj.tform);
        end
        
        % Assuming that image contained in obj.refimage.img contains a
        % calibration pattern, read and extract calibration points from the
        % image.
        function Read_Calibration_Pattern(obj)
            groundTruth = obj.Target; %Get projected pattern in DMD space
            
            result_sub = mat2gray(obj.allOnImage-obj.refimage.img); % all white image - calibration image
            result_sub = 1-imadjust(imflatfield(result_sub,0.1*min(size(result_sub)))); %flat field correction
            
            result = imadjust(mat2gray(imflatfield(obj.refimage.img,0.1*min(size(obj.refimage.img)))));
            % figure();
            % imshow(result);
            %Perform binarization just to get auto crop region
            binIm = imbinarize(1-result_sub,'adaptive');
            binIm = imopen(binIm,strel('disk',10));
            [nonZeroRows,nonZeroColumns] = find(binIm);
            topRow = min(nonZeroRows(:));
            bottomRow = max(nonZeroRows(:));
            leftColumn = min(nonZeroColumns);
            rightColumn = max(nonZeroColumns);
            cropped = cat(3,result,result_sub);
            
            if topRow > 1
                cropped(1:topRow-1,:,:) = 1;
            end
            if bottomRow < size(cropped,1)
                cropped(bottomRow+1:end,:,:) = 1;
            end
            if leftColumn > 1
                cropped(:,1:leftColumn-1,:) = 1;
            end
            if rightColumn < size(cropped,2)
                cropped(:,rightColumn+1:end,:) = 1;
            end
            
            %smooth and scale intensity to semi-binarize.
            for i = 1:size(cropped,3)
                smoothed(:,:,i) = medfilt2(cropped(:,:,i));
                final(:,:,i) = imadjust(smoothed(:,:,i),[0.1,0.7],[],2);
                final(:,:,i+size(cropped,3)) = imadjust(smoothed(:,:,i),[0.1,0.65],[],2);
                final(:,:,i+2*size(cropped,3)) = imadjust(smoothed(:,:,i),[0.1,0.75],[],2);
            end
            %Read tags
            % figure();
            % imshow(final);
            maxtags = 0;
            tagIds = [];
            tagLocs = [];
            besti = 1;
            for i = 1:size(final,3)
                [Ids, Locs] = readAprilTag(final(:,:,i),obj.APRILTAGFAMILY);
                if numel(Locs) > maxtags
                    maxtags = numel(Locs);
                    tagIds = Ids;
                    tagLocs = Locs;
                    besti = i;
                end
            end
            if isempty(tagIds) %In case pattern is mirror image, which will cause detection to fail
                final_mirror = permute(final,[2,1,3]);
                for i = 1:size(final,3)
                    [Ids, Locs] = readAprilTag(final_mirror(:,:,i),obj.APRILTAGFAMILY);
                    if numel(Locs) > maxtags
                        maxtags = numel(Locs);
                        tagIds = Ids;
                        tagLocs = Locs;
                        besti = i;
                    end
                end
                tagLocs = flip(tagLocs,2);
            end
            if isempty(tagIds)
                figure();
                montage(final);
                error("Calibration Failed: Try a thin sample with good focus");
            end
            % Sort the tags based on their ID values.
            [~, sortIdx] = sort(tagIds);
            tagLocs = tagLocs(:,:,sortIdx);
            % Reshape the tag corner locations into an M-by-2 array.
            tagLocs_vec = reshape(permute(tagLocs,[1,3,2]),[],2);
            
            % Display corner locations.
            figure; tiledlayout('flow');
            
            plot(tagLocs_vec(:,1),tagLocs_vec(:,2),"ro-",MarkerSize=15)
            for i = 1:numel(tagIds)
                center = mean(tagLocs(:,:,i));
                text(center(1),center(2),string(tagIds(i)),'FontSize',24,'Color','red');
            end
            
            nexttile();
            title("Reference tag locations");
            imshow(groundTruth); hold on;
            
            %Compare with groundTruth locations
            [tagIds_gt, tagLocs_gt] = readAprilTag(groundTruth,obj.APRILTAGFAMILY);
            % Sort the tags based on their ID values.
            [~, sortIdx_gt] = sort(tagIds_gt);
            tagLocs_gt = tagLocs_gt(:,:,sortIdx_gt);
            tagLocs_gt_vec = [];
            for i = 1:numel(tagIds)
                tagLocs_gt_vec = [tagLocs_gt_vec; tagLocs_gt(:,:,find(tagIds_gt == tagIds(i)))];
            end
            plot(tagLocs_gt_vec(:,1),tagLocs_gt_vec(:,2),"ro-",MarkerSize=15)
            for i = 1:numel(tagIds_gt)
                center = mean(tagLocs_gt(:,:,i));
                text(center(1),center(2),string(tagIds_gt(i)),'FontSize',24,'Color','red');
            end
            
            transformType = 'projective';
            if isMATLABReleaseOlderThan("R2022b")
                %Make sure the order of the matcoords coordinates is
                %correct.
                %Three points defines an affine transformation.
                %We probably want to use four points and thereby generalize
                %to projective transformations, which don't preserve
                %parallelism, but are still linear.
                [finaltform, ~, ~, status] = estimateGeometricTransform(tagLocs_vec, tagLocs_gt_vec, ...
                    transformType); %old pre-R2022b convention
            else
                if size(tagLocs_vec,1) > 14
                    %Nonlinear
                    finaltform = fitgeotform2d(tagLocs_vec, tagLocs_gt_vec, ...
                        "polynomial",4); %new premultiply convention
                else
                    %Linear
                    finaltform = estgeotform2d(tagLocs_vec, tagLocs_gt_vec, ...
                        transformType); %new premultiply convention
                end
                
                
            end
            
            %visualization
            fixed = mat2gray(obj.Target);
            moving = mat2gray(final(:,:,besti));
            Rfixed = imref2d(size(fixed));
            figure
            tiledlayout("flow");
            nexttile();
            imagesc(fixed);
            title("Displayed Pattern");
            axis image;
            nexttile();
            title("Registered Camera Image");
            movingRegistered_est = imwarp(moving, finaltform, 'OutputView', Rfixed);
            imagesc(movingRegistered_est)
            axis image
            nexttile();
            imshowpair(movingRegistered_est,fixed);
            axis image;
            title("Overlay");
            
            obj.tform = finaltform;
            obj.Initializer.tform = obj.tform;
            obj.additionalConfigData.set("tform", obj.tform);
        end
        
        % Generate calibration pattern and save to obj.Target
        function Generate_Calibration_Pattern(obj,min_tags_per_side)
            arguments
                obj Patterning_Device
                min_tags_per_side (1,1) = 4;
            end
            obj.allOnImage = obj.refimage.img; %Assume all white image is displayed before displaying cal pattern.
            tagImageFolder = fullfile(helperAprilTagLocation(),obj.APRILTAGFAMILY);
            imdsTags = imageDatastore(tagImageFolder);
            calibPattern = helperGenerateAprilTagPattern_canvasSize(imdsTags, obj.Dimensions,min_tags_per_side,obj.APRILTAGFAMILY);
            obj.Target = calibPattern;
            
        end
        
        
    end
    
    %This attempts to calibrate using image of spots, but is very slow and
    %doesn't work very well. Doing point centroid extraction would be
    %better.
    
    % methods (Static, Hidden = true)
    %     function finaltform = RefT(fixed, snapimage, smoothing, manualestimate, MovingRef)
    %         fixed = double(fixed);
    %         fixed = imgaussfilt(fixed, smoothing);
    %         Rfixed = imref2d(size(fixed));
    %         [optimizer, metric] = imregconfig('multimodal');
    %         optimizer.InitialRadius = optimizer.InitialRadius / 10;
    %         optimizer.MaximumIterations = 500;
    %         moving = imgaussfilt(snapimage, smoothing);
    %         %CAUTION: Before R2022b, imregtform returns an affine2d object.
    %         %Starting with R2022b, it returns an affinetform2d
    %         %pre-multiplying transform. Imwarp can handle either type
    %         %automatically, but be aware.
    %         finaltform = imregtform(moving, MovingRef, fixed, Rfixed, ...
    %             'affine', optimizer, metric, 'InitialTransformation', manualestimate);
    %         movingRegistered = imwarp(moving, MovingRef, finaltform, 'OutputView', Rfixed);
    %         figure
    %         subplot(1, 2, 1)
    %         imagesc(fixed./max(fixed(:)));
    %         subplot(1, 2, 2)
    %         imagesc(movingRegistered./max(movingRegistered(:)));
    %
    %     end
    %
    % end
end
