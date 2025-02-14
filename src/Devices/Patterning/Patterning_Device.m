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
        all_patterns
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
        
        % Load and compress current pattern stack 
        function packedData = loadDmdPatterns(obj)
            arguments 
                obj
            end
        
            % Assume data is your 2D or 3D DMD pattern matrix
            binaryData = logical(obj.all_patterns);  % Convert to binary (logical) array
            
            % Reshape to 1D array for easier processing
            binaryDataFlat = binaryData(:);
            
            % Pad binaryDataFlat to a multiple of 8 if needed
            paddingLength = 8 - mod(numel(binaryDataFlat), 8);
            if paddingLength < 8
                binaryDataFlat = [binaryDataFlat; false(paddingLength, 1)];
            end
            
            % Convert to double for multiplication, then reshape to groups of 8 bits
            binaryDataDouble = double(binaryDataFlat);
            reshapedData = reshape(binaryDataDouble, 8, []).';
        
            % Pack each group of 8 bits into a single byte
            packedData = uint8(reshapedData * (2 .^ (0:7)).');
        end


        % Load DMD dimensions
        function dims = getDmdDimensions(obj)
            arguments 
                obj
            end
            
            dims = obj.Dimensions;
        end

        
        % Modified setPatterningROI function that corrects for FOV offset.
        % Method depends on tform. Need to check using Galvo and SLM,
        % as those don't correct for FOV currently, so if calibration is
        % run with an offset this will overcorrect.
        function tmask = setPatterningROI(obj, rmask, options)
            arguments
                obj
                rmask
                options.write_when_complete logical = true
            end
            
            if isempty(obj)
                error("Error: DMD is not found.");
            end
            if ~isempty(obj.tform) && ~isempty(obj.refimage)
                if isa(obj.tform, "affinetform2d") || isa(obj.tform, "projtform2d")
                    transform_inv = invert(obj.tform);
                    transform_inv.A(1,3) = transform_inv.A(1,3) - obj.refimage.ref2d.XWorldLimits(1);
                    transform_inv.A(2,3) = transform_inv.A(2,3) - obj.refimage.ref2d.YWorldLimits(1);
                    transform = invert(transform_inv);
                elseif isa(obj.tform, "affine2d") || isa(obj.tform, "projective2d")
                    transform_inv = invert(obj.tform);
                    transform_inv.T(3,1) = transform_inv.T(3,1) - obj.refimage.ref2d.XWorldLimits(1);
                    transform_inv.T(3,2) = transform_inv.T(3,2) - obj.refimage.ref2d.YWorldLimits(1);
                    transform = invert(transform_inv);
                else
                    % Polynomial is not invertible, so use shifted
                    % offset mask instead.
                    transform = obj.tform;
                end
            else
                %disp("No ref tforms found. Return eye(3).");
                transform = affine2d(eye(3)); % This may be unnecessary. Adding warning to see if this case ever happens.
                % If it does, there should be a check for MATLAB version here.
                %  - DI 7/24
            end
            Rfixed = imref2d([obj.Dimensions(1), obj.Dimensions(2)]);
            
            % upsample to 2048 x 2048 or the size of the reference image
            if ~isempty(obj.refimage)
                newSize = size(obj.refimage.img)*obj.refimage.bin;
            else
                newSize = [2048, 2048];
            end
            
            %When drawing a circle with the center outside of the DMD, rmask
            % gets passed in the wrong format for some reason.
            %  This code is to put it in the back
            % right format if this happens. - DI 7/24
            if iscell(rmask)
                minindex = +inf;
                for i=1:length(rmask)
                    minindex = min(size(rmask{i}),minindex);
                end
                for j=1:length(rmask)
                    rmask{j} = rmask{j}(1:minindex);
                end
                rmask = horzcat(rmask{1:end})';
            end
            
            rmask = imresize(rmask, newSize);
            
            % Offset to make selection FOV agnostic. For some reason this
            % only works with polynomial tform, so we need to do double
            % invert for affine.
            if  ~exist('transform_inv','var') && ~isempty(obj.refimage)
                x_offset = obj.refimage.ref2d.XWorldLimits(1);
                y_offset = obj.refimage.ref2d.YWorldLimits(1);
                [height, width] = size(rmask);
                new_height = height + y_offset;
                new_width = width + x_offset;
                new_rmask = zeros(new_height, new_width);
                new_rmask(y_offset+1:end, x_offset+1:end) = rmask;
                rmask = new_rmask;
            end
            
            % apply transformation from image space to patterning device space
            tmask = imwarp(rmask, transform, 'OutputView', Rfixed);
            
            if options.write_when_complete
                if obj.smoothing == 0
                    obj.Target = tmask;
                else
                    obj.Target = imgaussfilt(double(tmask), obj.smoothing);
                end
                obj.Write_Static();
                tmask = 1;
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
            if isempty(obj)
                % Don't spam errors if DMD is not connected.
                return;
            end
            
            % Extract date and file information from filename
            [pathstr, name, ext] = fileparts(filename);
            date_str = regexp(pathstr, '\d{8}', 'match', 'once'); % Assumes date is an 8-digit number in the path
            
            % Convert date string to a datetime for manipulation
            current_date = datetime(date_str, 'InputFormat', 'yyyyMMdd');
            yesterday_date = current_date - days(1);
            yesterday_str = datestr(yesterday_date, 'yyyymmdd');
            
            % Paths for current and yesterday's date
            current_mat_path = fullfile(pathstr, [name, '.mat']);
            current_mat_path = strrep(current_mat_path, date_str, datestr(current_date, 'yyyymmdd'));
            yesterday_mat_path = strrep(current_mat_path, date_str, yesterday_str);
            
            current_png_path = filename;
            yesterday_png_path = strrep(filename, date_str, yesterday_str);
            
            % Check if the file exists and load it
            if isfile(current_mat_path)
                obj.refimagefile = current_mat_path;
                lsnap = load(obj.refimagefile);
                obj.refimage = lsnap.snap;
            elseif isfile(yesterday_mat_path)
                obj.refimagefile = yesterday_mat_path;
                lsnap = load(obj.refimagefile);
                obj.refimage = lsnap.snap;
            elseif isfile(current_png_path)
                obj.refimagefile = current_png_path;
                % Handle any needed processing for png if applicable
            elseif isfile(yesterday_png_path)
                obj.refimagefile = yesterday_png_path;
                % Handle any needed processing for png if applicable
            else
                warning('Reference image file not found for either current or previous date.');
            end
        end
        
        function success = calculateCalibrationTransform(obj, pts, transformType)
            arguments
                obj Patterning_Device
                pts = [];
                transformType string = "";
            end
            
            if isempty(obj)
                error("Error: DMD is not found.");
            end
            
            if strcmp(transformType,"Manual calibration (affine)")
                success = obj.Manual_Calibration(pts);
            else
                success = obj.Read_Calibration_Pattern(transformType);
            end
            
        end
        
        function success = Manual_Calibration(obj, pts)
            %clear fig;
            fixed = obj.GenTargetFromSpots(obj.calpoints, obj.Dimensions, 10);
            
            %Determine what type of transform is appropriate. Could be
            %expanded. Minimum 4 pairs for projective.
            if size(obj.calpoints,1) >= 4
                transformType = "projective";
            elseif size(obj.calpoints,1) == 3
                transformType = "affine";
            end
            
            try
                % Account for binning to make tform binning agnostic
                pts = pts.*obj.refimage.ref2d.ImageSize;
                pts_bin = pts*obj.refimage.bin;

                % Find correct tform depending on MATLAB version
                if isMATLABReleaseOlderThan("R2022b")
                    t_est = estimateGeometricTransform(pts, obj.calpoints, transformType); % Old pre-R2022b convention
                    t_est_plot = estimateGeometricTransform(pts_bin, obj.calpoints, transformType);
                else
                    t_est = estgeotform2d(pts, obj.calpoints, transformType); % New premultiply convention
                    t_est_plot = estgeotform2d(pts_bin, obj.calpoints, transformType);
                end

                % Account for possible offset to make tform ROI agnostic
                if isa(t_est, "affinetform2d") || isa(t_est, "projtform2d")
                    transform_inv = invert(t_est);
                    transform_inv.A(1,3) = transform_inv.A(1,3) - obj.refimage.ref2d.XWorldLimits(1);
                    transform_inv.A(2,3) = transform_inv.A(2,3) - obj.refimage.ref2d.YWorldLimits(1);
                    t_est = invert(transform_inv);
                elseif isa(t_est, "affine2d") || isa(t_est, "projective2d")
                    transform_inv = invert(t_est);
                    transform_inv.T(3,1) = transform_inv.T(3,1) - obj.refimage.ref2d.XWorldLimits(1);
                    transform_inv.T(3,2) = transform_inv.T(3,2) - obj.refimage.ref2d.YWorldLimits(1);
                    t_est = invert(transform_inv);
                else
                    error("Incorrect tform type generated.");
                end
                
                Rfixed = imref2d(size(fixed));
                moving = imadjust(mat2gray(obj.refimage.img));
                movingRegistered = imwarp(moving, t_est_plot, 'OutputView', Rfixed);

                % Visualize results
                figure; tiledlayout('flow');
                sgtitle("Calibration Results Summary");
                nexttile();
                imshow(obj.Target'); hold on;
                title("Reference point locations");
                plot(obj.calpoints(:,2),obj.calpoints(:,1),"ro",'MarkerFaceColor','r',MarkerSize=5);
                nexttile();
                imshowpair(movingRegistered',fixed');
                axis image;
                title("Overlay");

                obj.tform = t_est;
                
                if obj.debug_mode == 1
                    imagesc(obj.demo_ax(2), obj.Target);
                end
                
                % Update the tform in the additional config data regardless of path
                obj.additionalConfigData.set("tform", obj.tform);
                success = 1;
            catch
                %error("Calibration Failed: Try a thin sample with good focus.");
                success = 0;
                disp("Calibration failed. No tform generated.");
            end
        end
        
        % obj.refimage.img contains current AprilTag calibration pattern.
        % read and extract calibration points from the image.
        function success = Read_Calibration_Pattern(obj, transformType)
            success = false;
            groundTruth = obj.Target; %Get projected pattern in DMD space
            
            result_sub = mat2gray(obj.allOnImage-obj.refimage.img); % all white image - calibration image
            result_sub = 1-imadjust(imflatfield(result_sub,0.1*min(size(result_sub)))); %flat field correction
            
            result = imadjust(mat2gray(imflatfield(obj.refimage.img,0.1*min(size(obj.refimage.img)))));
            
            %Perform binarization just to get auto crop region
            disksize = floor(10/obj.refimage.bin);
            binIm_1 = imbinarize(1-result_sub,'adaptive');
            binIm = imopen(binIm_1,strel('disk',disksize));
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
                disp("Calibration Failed: No tags found. Make sure at least one tag is well visible in ROI. Try a thin sample with good focus.");
                success = false;
                return;
            end

            % Sort the tags based on their ID values.
            [~, sortIdx] = sort(tagIds);
            tagLocs = tagLocs(:,:,sortIdx);

            % Reshape the tag corner locations into an M-by-2 array.
            tagLocs_vec = reshape(permute(tagLocs,[1,3,2]),[],2);
            
            % Account for binning
            tagLocs_vec_bin = tagLocs_vec*obj.refimage.bin;
            
            %Compare with groundTruth locations
            [tagIds_gt, tagLocs_gt] = readAprilTag(groundTruth,obj.APRILTAGFAMILY);

            % Sort the tags based on their ID values.
            [~, sortIdx_gt] = sort(tagIds_gt);
            tagLocs_gt = tagLocs_gt(:,:,sortIdx_gt);
            tagLocs_gt_vec = [];
            for i = 1:numel(tagIds)
                tagLocs_gt_vec = [tagLocs_gt_vec; tagLocs_gt(:,:,find(tagIds_gt == tagIds(i)))];
            end
            for i = 1:numel(tagIds_gt)
                center = mean(tagLocs_gt(:,:,i));
            end
            
            %Estimate transform
            if (transformType == "4th Degree Polynomial transform" && (size(tagLocs_vec,1) < 17))
                enoughForPolynomial4 = false;
                if ~(size(tagLocs_vec,1) < 9)
                    enoughForPolynomial2 = true;
                    disp("Insufficient number of points for 4th Degree Polynomial calibration. 2nd Degree instead.");
                else
                    enoughForPolynomial2 = false;
                    disp("Insufficient number of points for polynomial calibration. Using affine instead.");
                end
            elseif (transformType == "2nd Degree Polynomial transform" && (size(tagLocs_vec,1) < 9))
                enoughForPolynomial2 = false;
                disp("Insufficient number of points for polynomial calibration. Using affine instead.");
            else
                enoughForPolynomial2 = true;
                enoughForPolynomial4 = true;
            end
            
            oldRelease = isMATLABReleaseOlderThan("R2022b");
            
            if transformType == "Affine transform" || ~enoughForPolynomial2
                if oldRelease
                    %Three points defines an affine transformation.
                    %Note DI 6/24: Changed back to affine as default. projective transform
                    %has poor conditioning when points are clustered far away
                    %from origin, this is especially bad large sensors and low
                    %magnification. One way to fix this is might be to subtract COM coordinates from
                    %Camera image, separately transform COM and points and then
                    %re-add together? Affine does not have this issue.
                    [finaltform, ~, ~, status] = estimateGeometricTransform(tagLocs_vec_bin, tagLocs_gt_vec, ...
                        "affine"); %old pre-R2022b convention
                    [finaltform_plot, ~, ~, status] = estimateGeometricTransform(tagLocs_vec, tagLocs_gt_vec, ...
                        "affine");
                else
                    % Different tform to account for new premultiply convention
                    finaltform = estgeotform2d(tagLocs_vec_bin, tagLocs_gt_vec, ...
                        "affine");
                    finaltform = estgeotform2d(tagLocs_vec, tagLocs_gt_vec, ...
                        "affine");
                    finaltform_plot = finaltform;
                end
                
            elseif transformType == "Projective transform"
                if oldRelease
                    %Generalize to projective transformations, which don't preserve
                    %parallelism, but are still linear. Can be inaccurate for large FOV.
                    [finaltform, ~, ~, status] = estimateGeometricTransform(tagLocs_vec_bin, tagLocs_gt_vec, ...
                        "projective"); %old pre-R2022b convention
                    [finaltform_plot, ~, ~, status] = estimateGeometricTransform(tagLocs_vec, tagLocs_gt_vec, ...
                        "projective");
                else
                    % Different tform to account for new premultiply convention
                    finaltform = estgeotform2d(tagLocs_vec_bin, tagLocs_gt_vec, ...
                        "projective");
                    finaltform_plot = estgeotform2d(tagLocs_vec, tagLocs_gt_vec, ...
                        "projective");
                end
                
                % Polynomial transforms
                % In my hands polynomial 4 actually tends to perform worse
                % than 2 due to overfitting. - DI 7/24
            elseif transformType == "2nd Degree Polynomial transform" || ~enoughForPolynomial4
                x_offset = obj.refimage.ref2d.XWorldLimits(1);
                y_offset = obj.refimage.ref2d.YWorldLimits(1);
                tagLocs_vec_offset = tagLocs_vec_bin + [x_offset, y_offset];
                if oldRelease
                    finaltform = fitgeotrans(tagLocs_vec_offset, tagLocs_gt_vec,"polynomial",2);
                    finaltform_plot = fitgeotrans(tagLocs_vec, tagLocs_gt_vec,"polynomial",2);
                else
                    finaltform = fitgeotform2d(tagLocs_vec_offset, tagLocs_gt_vec,"polynomial",2);
                    finaltform_plot = fitgeotform2d(tagLocs_vec, tagLocs_gt_vec,"polynomial",2);
                end
            elseif transformType == "4th Degree Polynomial transform"
                x_offset = obj.refimage.ref2d.XWorldLimits(1);
                y_offset = obj.refimage.ref2d.YWorldLimits(1);
                tagLocs_vec_offset = tagLocs_vec_bin + [x_offset, y_offset];
                if oldRelease
                    finaltform = fitgeotrans(tagLocs_vec_offset, tagLocs_gt_vec,"polynomial",4);
                    finaltform_plot = fitgeotrans(tagLocs_vec, tagLocs_gt_vec,"polynomial",4);
                else
                    finaltform = fitgeotform2d(tagLocs_vec_offset, tagLocs_gt_vec,"polynomial",4);
                    finaltform_plot = fitgeotform2d(tagLocs_vec, tagLocs_gt_vec,"polynomial",4);
                end
            else
                error("Invalid transform type. Must be 'Affine transform', 'Projective transform', '2nd Degree Polynomial transform', or '4th Degree Polynomial transform'.");
            end
            
            fixed = mat2gray(obj.Target);
            moving = mat2gray(final(:,:,besti));
            Rfixed = imref2d(size(fixed));
            movingRegistered_est = imwarp(moving, finaltform_plot, 'OutputView', Rfixed);

            %Visualize the results
            figure; tiledlayout('flow');
            sgtitle("Calibration Results Summary");
            nexttile();
            imshow(groundTruth); hold on;
            title("Reference tag locations");
            plot(tagLocs_gt_vec(:,1),tagLocs_gt_vec(:,2),"ro",'MarkerFaceColor','r',MarkerSize=5);
            nexttile();
            imshowpair(movingRegistered_est,fixed);
            axis image;
            title("Overlay");
            
            % Modify transform to make it FOV agnostic
            if isa(finaltform, "affinetform2d") || isa(finaltform, "projtform2d")
                finaltform_inv = invert(finaltform);
                finaltform_inv.A(1,3) = finaltform_inv.A(1,3) + obj.refimage.ref2d.XWorldLimits(1);
                finaltform_inv.A(2,3) = finaltform_inv.A(2,3) + obj.refimage.ref2d.YWorldLimits(1);
                finaltform_shifted = invert(finaltform_inv);
            elseif isa(finaltform, "affine2d") || isa(finaltform, "projective2d")
                finaltform_inv = invert(finaltform);
                finaltform_inv.T(3,1) = finaltform_inv.T(3,1) + obj.refimage.ref2d.XWorldLimits(1);
                finaltform_inv.T(3,2) = finaltform_inv.T(3,2) + obj.refimage.ref2d.YWorldLimits(1);
                finaltform_shifted = invert(finaltform_inv);
            else
                finaltform_shifted = finaltform;
            end
            
            obj.tform = finaltform_shifted;
            obj.Initializer.tform = finaltform_shifted;
            obj.additionalConfigData.set("tform", finaltform_shifted);
            success = true;
        end
        
        % Generate calibration pattern and save to obj.Target
        function Generate_Calibration_Pattern(obj,min_tags_per_side)
            arguments
                obj Patterning_Device
                min_tags_per_side (1,1) = 4;
            end
            %When running calibration, all white image is displayed before displaying cal pattern.
            % When just previewing, this is not necessarily true.
            if ~isempty(obj.refimage)
                obj.allOnImage = obj.refimage.img; 
            end
            tagImageFolder = fullfile(helperAprilTagLocation(),obj.APRILTAGFAMILY);
            imdsTags = imageDatastore(tagImageFolder);
            calibPattern = helperGenerateAprilTagPattern_canvasSize(imdsTags, obj.Dimensions,min_tags_per_side,obj.APRILTAGFAMILY);
            obj.Target = calibPattern;
            
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
    
    methods (Sealed)
        function dims = ref_im_dims(obj)
            if isempty(obj)
                dims = [0, 0];
                return;
            end
            
            if ~isempty(obj.refimage)
                dims = size(obj.refimage.img);
            else
                dims = [0, 0];
            end
        end
        
        function determ = ref_im_tform(obj)
            if isempty(obj)
                determ = 0;
                return;
            end
            
            if ~isempty(obj.tform)
                if isa(obj.tform, "affinetform2d") || isa(obj.tform, "projtform2d")
                    determ = sqrt(abs(det(obj.tform.A(1:2,1:2))));
                elseif isa(obj.tform, "affine2d") || isa(obj.tform, "projective2d")
                    determ = sqrt(abs(det(obj.tform.T(1:2,1:2))));
                else
                    % Polynomial tform
                    determ = sqrt(abs(det([obj.tform.A(2), obj.tform.A(3); obj.tform.B(2), obj.tform.B(3)])));
                end
            else
                %disp("No tforms found. Return 0.");
                determ = 0;
            end
        end
    end
    
end