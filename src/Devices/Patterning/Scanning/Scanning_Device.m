classdef Scanning_Device < Patterning_Device

    properties (Transient)
        app Rig_Control_App
        Stage Motion_Controller
    end

    properties
        scanbounds (1, 4) double
        timebase_source (1, :) char
        trigger_physport (1, :) char
        PMT_physport (1, :) char
        galvofbx_physport (1, :) char
        galvofby_physport (1, :) char
        galvox_physport (1, :) char
        galvoy_physport (1, :) char
        sync_counter (1, :) char
        sample_rate double
        DAQ_Vendor uint16
        galvox_wfm
        galvoy_wfm
        vbounds
        feedback_scaling
        max_sampling_rate
        mexPointer
        samples_per_pixel = 2
        Points_Per_Volt = 10;
        initialized = false
        roi_meta
        volts_per_pixel
        camera_detection = 0
        raster_bounds
        self_referenced = false;
        galvos_only;
        fixed_rep_rate_flag = true; %Should device adjust point density to attain set rep rate?
        period = 0.01; %Desired target pattern repeat period (only applies if fixed_rep_rate_flag == true)
        MICRONS_PER_CAMERA_PIXEL = 0.350;
    end

    properties
        outputdata = Scanning_Output_Data.empty;
        points_per_line;
        numlines;
        dwell_time = 0;
        roi_type = 'None'
        total_frames;
    end

    properties (SetObservable, AbortSet) %abortset prevents triggering the set listener if new value is the same as old.
        frame_rate;
    end

    methods

        function Wait_Until_Done(obj)
            if (obj.camera_detection == 0) && (~strcmp('ZStack', obj.outputdata.type))
                obj.Get_SyncFrame_Data();
            else
                obj.camera_detection = 0;
            end
        end
    end

    methods
        function obj = Scanning_Device(Initializer)
            obj@Patterning_Device(Initializer);
            obj.calpoints = [0, 2; 1, 2; -2, 0]; %NOTE THIS SHOULD BE REPLACED WITH obj.calpoints=(obj.frac_calpoints-.5)*10;
            obj.roi_type = 'Raster';
            obj.scanbounds = [-5, -5, 5, 5]; %Assuming -5 to 5 V scan
        end

        function Startup(obj)
            obj.mexPointer = SCANNING_MEX('new', obj);
            SCANNING_MEX('Raster_From_Bounds', obj, obj.vbounds);
            obj.initialized = true;
        end

        function startup_js(obj)
            if ~obj.initialized
                obj.mexPointer = SCANNING_MEX('new', obj);
                obj.initialized = true;
                obj.Raster_Galvos_From_Bounds(obj.scanbounds, obj.Points_Per_Volt);
            end
        end

        function delete(obj)
            if obj.initialized
                SCANNING_MEX('Mex_Cleanup', obj);
            end
        end

        % seems to not work due to memory issues
        % function deleteJs(obj)
        %     if obj.initialized
        %         SCANNING_MEX('Mex_Cleanup',obj);
        %         obj.initialized = false;
        %     end
        %
        % end

        function framerate = points_per_volt_to_framerate(obj, ppv)
            switch obj.roi_type
                case 'Raster'
                    widthv = obj.scanbounds(3) - obj.scanbounds(1);
                    heightv = obj.scanbounds(4) - obj.scanbounds(2);
                    numpoints = 2 * widthv * heightv * ppv^2;
                case 'Points'
                    numpoints = numel(obj.Target(:, 1));
                case 'Curve'
                    resampled_points = resample_curve(obj.Target, ppv, true, false);
                    numpoints = numel(resampled_points);
                case 'Spiral'
                    numpoints = ppv.^2 * obj.roi_meta.scan_area; %    r=sqrt(numpoints/pi)/points_per_volt;
                case 'Donut'
                    numpoints = ppv.^2 * obj.roi_meta.scan_area;
                otherwise
                    warning("Resample not defined for roi type: %s", obj.roi_type);
                    numpoints = 0;
                    %Add in cases for other rois.
            end
            framerate = obj.sample_rate / numpoints;
        end

        function ppv = framerate_to_points_per_volt(obj, framerate)
            numpoints = obj.sample_rate / framerate;
            switch obj.roi_type
                case 'Raster'
                    warning("Fixed frame rate not correctly implemented for raster region.")
                    %Not possible to guarantee that we can place an
                    %arbitrary number of samples (numpoints) in a regularly
                    %spaced grid of a given size. Perhaps leave off one
                    %corner (round grid size up to nearest nice number).
                    widthv = obj.scanbounds(3) - obj.scanbounds(1);
                    heightv = obj.scanbounds(4) - obj.scanbounds(2);
                    ppv = sqrt(numpoints / (widthv * heightv));
                case 'Points'
                    ppv = numel(obj.Target(:, 1));
                case 'Curve'
                    resampled_points = resample_curve(obj.Target, numpoints, true, true);
                    ppv = 1 / vecnorm(resampled_points(1, :) - resampled_points(2, :));
                case 'Spiral'
                    %r=sqrt(obj.roi_meta.scan_area/pi);
                    ppv = sqrt(numpoints / obj.roi_meta.scan_area); %r=sqrt(numpoints/(pi))/points_per_volt;
                case 'Donut'
                    ppv = sqrt(numpoints / (obj.roi_meta.scan_area));
                otherwise
                    warning("Resample not defined for roi type: %s", obj.roi_type);
                    ppv = 0;
                    %Add in cases for other rois.
            end
        end

        function mpp = framerate_to_microns_per_point(obj, framerate)
            obj.frame_rate = framerate;
            mpv = obj.MICRONS_PER_CAMERA_PIXEL / sqrt(abs(det(obj.tform.T))); % microns per volt
            obj.Points_Per_Volt = obj.framerate_to_points_per_volt(framerate);
            mpp = mpv / obj.Points_Per_Volt;
            obj.resample_roi();
        end

        function framerate = microns_per_point_to_framerate(obj, mpp)
            mpv = obj.MICRONS_PER_CAMERA_PIXEL / sqrt(abs(det(obj.tform.T))); % microns per volt
            obj.Points_Per_Volt = mpv / mpp;
            framerate = obj.points_per_volt_to_framerate(obj.Points_Per_Volt);
            obj.frame_rate = framerate;
            obj.resample_roi();
        end

        function resample_roi(obj)
            % gets called when framerate/microns per point is updated
            switch obj.roi_type
                case 'Raster'
                    obj.Raster_Galvos_From_Bounds(obj.scanbounds, obj.Points_Per_Volt);
                case 'Points'
                    % ppv=numel(obj.Target(:,1));
                    % continue
                case 'Curve'
                    resampled_points = resample_curve([obj.roi_meta.x, obj.roi_meta.y], obj.Points_Per_Volt, true, false);
                    obj.Project_Spots(resampled_points(:, 1), resampled_points(:, 2));
                case 'Spiral'
                    [xwfm, ywfm] = Calculate_Spiral_Scan(obj.roi_meta.trans_center, obj.roi_meta.trans_radius, obj.Points_Per_Volt);
                    obj.Project_Spots(xwfm, ywfm);
                case 'Donut'
                    [xwfm, ywfm] = Calculate_Donut_Scan(obj.roi_meta.trans_center, obj.roi_meta.trans_radius_outer, obj.roi_meta.trans_radius_inner, obj.Points_Per_Volt);
                    obj.Project_Spots(xwfm, ywfm);
                otherwise
                    warning("Resample not defined for roi type: %s", obj.roi_type);
                    ppv = 0;
                    %Add in cases for other rois.
            end
        end

        
        function set_framerate(obj, framerate)
            obj.Points_Per_Volt = obj.framerate_to_points_per_volt(framerate);
            
        end

        function framerate = get_framerate(obj)
            framerate = obj.points_per_volt_to_framerate(obj.Points_Per_Volt);
        end

        % does not seem to be used, see restart_live below instead
        function Relaunch(obj)
            out = SCANNING_MEX('Mex_Cleanup', obj);
            pause(1);
            obj.Startup();
        end

        function Acquire_Frames(obj, frames)
            obj.total_frames = frames;
            obj.outputdata = Scanning_Output_Data();
            obj.outputdata.type = 'frames';
            [error, obj.outputdata.galvofbx, obj.outputdata.galvofby, obj.outputdata.PMT] = ...
                SCANNING_MEX('Acq_Frames', obj, int32(frames));
            obj.Synchronize_WFM_Data();
            obj.outputdata.galvoy_wfm = obj.galvoy_wfm;
            obj.outputdata.galvox_wfm = obj.galvox_wfm;
            %             if(~isempty(obj.Stage))
            %                 obj.Stage.Update_Current_Position_Microns();
            %                 obj.outputdata.stage_position=[obj.Stage.x;obj.Stage.y;obj.Stage.z];
            %             end
            notify(obj, 'exp_finished');
        end

        function Acquire_ZStack(obj, thickness, numslices, frames_per_slice)
            obj.outputdata = Scanning_Output_Data();
            obj.outputdata.type = 'ZStack';
            dz = thickness / numslices;
            for i = 1:numslices
                [errorMsg, galvofbx, galvofby, PMT] = SCANNING_MEX('Acq_Frames', obj, int32(frames_per_slice));
                if (~isempty(obj.Stage))
                    obj.Stage.Update_Current_Position_Microns();
                    obj.outputdata.Append_Data(PMT, galvofbx, galvofby, [obj.Stage.x, obj.Stage.y, obj.Stage.z]');
                    obj.Stage.Step_Fixed(3, dz);
                else
                    obj.outputdata.Append_Data(PMT, galvofbx, galvofby, [0, 0, 0]');
                end
            end
            notify(obj, 'exp_finished');
        end

        function Update_Galvos_Explicit(obj, galvoxwfm, galvoywfm, options)
            arguments
                obj
                galvoxwfm
                galvoywfm
                options.LiveDisplayMode = true; %Need to add in control to turn this off.
                options.Live_DisplayBounds = -Inf;
            end
            obj.galvox_wfm = galvoxwfm;
            obj.galvoy_wfm = galvoywfm;
            xpixels = (max(galvoxwfm(:)) - min(galvoxwfm(:))) * obj.Points_Per_Volt / obj.samples_per_pixel;
            if (xpixels < 1)
                xpixels = 1;
            end
            ypixels = (max(galvoywfm(:)) - min(galvoywfm(:))) * obj.Points_Per_Volt / obj.samples_per_pixel;
            if (ypixels < 1)
                ypixels = 1;
            end

            if xpixels * ypixels > 4000000
                error("Number of pixels to be displayed is very large and may cause a low-level crash. Please decrease scan density or size");
            end

            errorMsg = SCANNING_MEX('Update_Galvo_Scan', obj, int64(xpixels), int64(ypixels));

        end
        function update_framerate(obj)
            disp("Updating Framerate");
            %Update frame_rate value
            obj.frame_rate = obj.sample_rate / numel(obj.galvoy_wfm);
            if obj.frame_rate < 0.01
                selection = uiconfirm(obj.app.UIFigure, sprintf("Low frame rate: %g. Continue or Abort?", obj.frame_rate), ...
                    "Low Frame Rate Warning", 'Options', {'Continue', 'Abort'}, 'DefaultOption', 2);
                if strcmp(selection, 'Abort')
                    warning("Canceling galvo update. Please change ROI parameters");
                    return
                end
            end
        end

        function Acquire_Sync_Frames(obj, frames)
            error = SCANNING_MEX('Sync_Waveform_From_Stream', obj);
            error = SCANNING_MEX('Acq_Sync_Frames', obj, int32(frames));
            display(error);
        end

        function Get_SyncFrame_Data(obj)
            [error, obj.outputdata.galvofbx, obj.outputdata.galvofby, ...
                obj.outputdata.PMT] = SCANNING_MEX('Read_AI_Data', obj);
            display(error);
        end
        
        %---------------------------------------------------------------------------
        % Calibration/Registration methods
        %----------------------------------------------------------------------------
        % Calibrate the galvos by projecting a pattern of points and recording the
        % resulting image.  The points are then used to calculate a transformation
        % matrix that maps the image to the points.
        function Project_Cal_Pattern(obj, num_points_to_show, options)
            arguments
                obj Scanning_Device;
                num_points_to_show
                options.holdtime = .01;
            end
            holdtime = options.holdtime;
            xpoints = obj.calpoints(1:num_points_to_show, 1);
            ypoints = obj.calpoints(1:num_points_to_show, 2);
            expxpoints = repmat(xpoints, [1, holdtime * obj.sample_rate])';
            expypoints = repmat(ypoints, [1, holdtime * obj.sample_rate])';
            obj.Update_Galvos_Explicit(expxpoints(:), expypoints(:));
            
        end

        function calculateCalibrationTransform(obj, pts)
            Width = .1;
            [X, Y] = meshgrid(-5:.002:5, -5:.002:5);
            gauss = @(x0, y0, w0) exp(-((X - x0).^2 + (Y - y0).^2)/w0.^2);
            Target = zeros(size(X));
            for i = 1:size(obj.calpoints, 1)
                Target = Target + gauss(obj.calpoints(i, 1), obj.calpoints(i, 2), Width);
            end
            for i = 1:size(obj.calpoints, 1)
                [row, col] = find(abs(X-obj.calpoints(i, 1)) < 1e-6 & abs(Y-obj.calpoints(i, 2)) < 1e-6);
                matcoord(i, :) = [row, col];
            end
            
            % estimate transform from matcoord to calpoints
            im2volts_t = estimateGeometricTransform([matcoord(:, 2), matcoord(:, 1)], obj.calpoints, 'affine');

            display(pts)
            
            % estimate transform from selected points to matcoord
            [t_est, ~, ~, status] = estimateGeometricTransform(pts, [matcoord(:, 2), matcoord(:, 1)], ...
            'affine');
            fixed = double(Target);
            fixed = imgaussfilt(fixed, 5);
            Rfixed = imref2d(size(fixed));
            [optimizer, metric] = imregconfig('multimodal');
            optimizer.InitialRadius = optimizer.InitialRadius / 10;
            optimizer.MaximumIterations = 100;
            moving = imgaussfilt(obj.refimage.img, 5);
            fixed = fixed ./ max(fixed(:));
            moving = moving ./ max(moving(:));
            %imregtform is deprecated in favor of
            %imregtform2d. Should replace.
            finaltform = imregtform(moving, fixed, ...
                'affine', optimizer, metric, 'InitialTransformation', t_est);
            movingRegistered = imwarp(moving, finaltform, 'OutputView', Rfixed);

            figure
            subplot(1, 2, 1)
            imagesc(fixed./max(fixed(:)));
            axis image;
            subplot(1, 2, 2)
            imagesc(5*movingRegistered./max(movingRegistered(:)))
            axis image
            obj.tform = finaltform;
            obj.tform.T = finaltform.T * im2volts_t.T;
            obj.Initializer.tform = obj.tform.T;
            obj.volts_per_pixel = sqrt(sum((obj.calpoints(1, :) - obj.calpoints(end, :)).^2)/sum((transformPointsInverse(obj.tform, obj.calpoints(1, :)) - transformPointsInverse(obj.tform, obj.calpoints(end, :))).^2));
            
            % update the tform in the additional config data
            obj.additionalConfigData.set("tform", obj.tform);
        end

        % Note: I think this function is no longer used
        function Cal_TForm(obj)
            Width = .1;
            [X, Y] = meshgrid(-5:.002:5, -5:.002:5);
            gauss = @(x0, y0, w0) exp(-((X - x0).^2 + (Y - y0).^2)/w0.^2);
            Target = zeros(size(X));
            for i = 1:size(obj.calpoints, 1)
                Target = Target + gauss(obj.calpoints(i, 1), obj.calpoints(i, 2), Width);
            end
            for i = 1:size(obj.calpoints, 1)
                [row, col] = find(abs(X-obj.calpoints(i, 1)) < 1e-6 & abs(Y-obj.calpoints(i, 2)) < 1e-6);
                matcoord(i, :) = [row, col];
            end
            im2volts_t = estimateGeometricTransform([matcoord(:, 2), matcoord(:, 1)], obj.calpoints, 'affine');
            roi = drawpolyline(obj.tax);
            display(roi.Position)
            [t_est, ~, ~, status] = estimateGeometricTransform(roi.Position, [matcoord(:, 2), matcoord(:, 1)], ...
            'affine');
            fixed = double(Target);
            fixed = imgaussfilt(fixed, 5);
            Rfixed = imref2d(size(fixed));
            [optimizer, metric] = imregconfig('multimodal');
            optimizer.InitialRadius = optimizer.InitialRadius / 10;
            optimizer.MaximumIterations = 100;
            moving = imgaussfilt(obj.testimage, 5);
            fixed = fixed ./ max(fixed(:));
            moving = moving ./ max(moving(:));
            %imregtform is deprecated in favor of
            %imregtform2d. Should replace.
            finaltform = imregtform(moving, fixed, ...
                'affine', optimizer, metric, 'InitialTransformation', t_est);
            movingRegistered = imwarp(moving, finaltform, 'OutputView', Rfixed);

            figure
            subplot(1, 2, 1)
            imagesc(fixed./max(fixed(:)));
            axis image;
            subplot(1, 2, 2)
            imagesc(5*movingRegistered./max(movingRegistered(:)))
            axis image
            obj.tform = finaltform;
            obj.tform.T = finaltform.T * im2volts_t.T;
            obj.Initializer.tform = obj.tform.T;
            obj.volts_per_pixel = sqrt(sum((obj.calpoints(1, :) - obj.calpoints(end, :)).^2)/sum((transformPointsInverse(obj.tform, obj.calpoints(1, :)) - transformPointsInverse(obj.tform, obj.calpoints(end, :))).^2));
        end

        %---------------------------------------------------------------------------
        % ROI/Scan control methods
        %----------------------------------------------------------------------------

        function Raster_Scan(obj, xmin, ymin, xmax, ymax)
            %Simple Wrapper to facilitate GUI autogeneration.
            obj.scanbounds = [xmin, ymin, xmax, ymax];
            obj.Raster_Galvos_From_Bounds(obj.scanbounds, obj.Points_Per_Volt);
        end

        function Raster_Galvos_From_Bounds(obj, bounds, points_per_volt)
            if ~obj.initialized
                return
            end
            %Hunter is hacking this but will fix it. Issue with live display roi.
            obj.Points_Per_Volt = points_per_volt / 4; %autoextracted in mex file.
            obj.raster_bounds = bounds;
            SCANNING_MEX('Raster_From_Bounds', obj, bounds); %Automatically copies back generated waveforms
            obj.Points_Per_Volt = points_per_volt;
            obj.roi_type = 'Raster';
        end

        function Raster_Galvos_From_Bounds_Sawtooth(obj, bounds, points_per_volt)
            obj.Points_Per_Volt = points_per_volt; %autoextracted in mex file
            SCANNING_MEX('Sawtooth_Raster_From_Bounds', obj, bounds); %Automatically copies back generated waveforms
            obj.roi_type = 'Raster';
        end

        function snap = Snap(obj)
            obj.Acquire_Frames(1);
            snap = CL_RefImage();
            [snap.img, snap.xdata, snap.ydata] = Construct_Scanning_Frames([], 'live_device', obj);
            snap.tform = obj.tform;
            snap.type = 'Scanning_Device';
            snap.name = obj.name;
        end

        function Synchronize_WFM_Data(obj)
            SCANNING_MEX('Sync_Waveform_From_Stream', obj);
        end

        function Load_Ref_Im(obj)
            Load_Ref_Im@Patterning_Device(obj);
            if strcmp(obj.refimage.type, 'Scanning_Device') && strcmp(obj.refimage.name, obj.name)
                obj.self_referenced = true;
            else
                obj.self_referenced = false;
            end
        end

        function Project_Spots(obj, xpoints, ypoints, options)
            arguments
                obj Scanning_Device;
                xpoints (:, 1) double % Ensure xpoints is a column vector
                ypoints (:, 1) double % Ensure ypoints is a column vector
                options.dwell_time = obj.dwell_time;
            end
            if ~obj.initialized
                return
            end

            if options.dwell_time > 0
                expxpoints = repmat(xpoints, [1, round(options.dwell_time*obj.sample_rate)])';
                expypoints = repmat(ypoints, [1, round(options.dwell_time*obj.sample_rate)])';
            else
                expxpoints = xpoints;
                expypoints = ypoints;
            end
            obj.Update_Galvos_Explicit(expxpoints(:), expypoints(:));
        end

        function restart_live(obj)
            SCANNING_MEX('Restart_Live', obj);
        end

        function Gen_Raster_JS(obj, rect)
            obj.roi_type = 'Raster';
            % rect = {xmin, ymin, xmax, ymax}
            rect.xmin = double(obj.refimage.xdata(rect.xmin));
            rect.xmax = double(obj.refimage.xdata(rect.xmax));
            rect.ymin = double(obj.refimage.ydata(rect.ymin));
            rect.ymax = double(obj.refimage.ydata(rect.ymax));
            scanbounds_pretrans = [rect.xmin, rect.ymin; rect.xmax, rect.ymax; rect.xmax, rect.ymin; rect.xmin, rect.ymax];
            if obj.self_referenced
                reorient_scanbounds = scanbounds_pretrans;
            else
                transform = obj.tform;
                reorient_scanbounds = transformPointsForward(transform, scanbounds_pretrans);
            end

            if obj.fixed_rep_rate_flag
                obj.framerate_to_microns_per_point(obj.frame_rate);
            end

            obj.scanbounds = [min(reorient_scanbounds(:, 1)), min(reorient_scanbounds(:, 2)), max(reorient_scanbounds(:, 1)), max(reorient_scanbounds(:, 2))];
            obj.Raster_Galvos_From_Bounds(obj.scanbounds, obj.Points_Per_Volt);

        end

        function Gen_Spiral_JS(obj, spiral)
            obj.roi_type = 'Spiral';
            % spiral = {centerx, centery, radius}

            % transform from snap pixels to volts (confocal) or camera pixels (camera)
            spiral.centerx = double(obj.refimage.xdata(spiral.centerx));
            spiral.centery = double(obj.refimage.ydata(spiral.centery));
            spiral.radius = double((obj.refimage.xdata(2) - obj.refimage.xdata(1)) * spiral.radius);

            if obj.self_referenced
                trans_center = [spiral.centerx, spiral.centery];
                trans_radius = spiral.radius;
            else
                transform = obj.tform;
                [trans_centerx, trans_centery] = transformPointsForward(transform, spiral.centerx, spiral.centery);
                trans_center = [trans_centerx, trans_centery];
                [trans_edgex, trans_edgey] = transformPointsForward(transform, spiral.centerx, spiral.centery + spiral.radius);
                trans_edge = [trans_edgex, trans_edgey];
                trans_radius = sqrt(sum((trans_edge - trans_center) .^ 2));
            end

            % save data for roi_meta
            obj.roi_meta.scan_area = pi * trans_radius ^ 2;
            obj.roi_meta.trans_center = trans_center;
            obj.roi_meta.trans_radius = trans_radius;

            if obj.fixed_rep_rate_flag
                obj.framerate_to_microns_per_point(obj.frame_rate);
            end

            [xwfm, ywfm] = Calculate_Spiral_Scan(trans_center, trans_radius, obj.Points_Per_Volt);
            obj.Target = [xwfm', ywfm'];


            obj.Project_Spots(xwfm, ywfm);
        end

        function Gen_Donut_JS(obj, donut)
            obj.roi_type = 'Donut';
            % donut = {centerx, centery, innerRadius, outerRadius}

            donut.centerx = double(obj.refimage.xdata(donut.centerx));
            donut.centery = double(obj.refimage.ydata(donut.centery));
            donut.innerRadius = double((obj.refimage.xdata(2) - obj.refimage.xdata(1)) * donut.innerRadius);
            donut.outerRadius = double((obj.refimage.xdata(2) - obj.refimage.xdata(1)) * donut.outerRadius);

            if obj.self_referenced
                trans_center = [donut.centerx, donut.centery];
                trans_radius_outer = donut.outerRadius;
                trans_radius_inner = donut.innerRadius;
            else
                transform = obj.tform;
                [trans_centerx, trans_centery] = transformPointsForward(transform, donut.centerx, donut.centery);
                trans_center = [trans_centerx, trans_centery];

                [trans_edgex, trans_edgey] = transformPointsForward(transform, donut.centerx, donut.centery + donut.outerRadius);
                trans_edge = [trans_edgex, trans_edgey];
                trans_radius_outer = sqrt(sum((trans_edge - trans_center) .^ 2));

                [trans_edgex2, trans_edgey2] = transformPointsForward(transform, donut.centerx, donut.centery + donut.innerRadius);
                trans_edge2 = [trans_edgex2, trans_edgey2];
                trans_radius_inner = sqrt(sum((trans_edge2 - trans_center) .^ 2));
            end

            obj.roi_meta.scan_area = pi * (trans_radius_outer ^ 2 - trans_radius_inner ^ 2);
            obj.roi_meta.trans_center = trans_center;
            obj.roi_meta.trans_radius_outer = trans_radius_outer;
            obj.roi_meta.trans_radius_inner = trans_radius_inner;

            if obj.fixed_rep_rate_flag
                obj.framerate_to_microns_per_point(obj.frame_rate);
            end

            [xwfm, ywfm] = Calculate_Donut_Scan(trans_center, trans_radius_outer, trans_radius_inner, obj.Points_Per_Volt);
            obj.Target = [xwfm', ywfm'];

            obj.Project_Spots(xwfm, ywfm);
        end

        function Gen_Freeform_JS(obj, xPoints, yPoints)
            obj.roi_type = 'Curve';
            % xPoints = [x1, x2, x3, ...]
            xPoints = double(obj.refimage.xdata(xPoints));
            yPoints = double(obj.refimage.ydata(yPoints));

            % remove duplicate points
            arrNoDups = unique([xPoints; yPoints]', 'rows', 'stable');
            xPoints = arrNoDups(:, 1);
            yPoints = arrNoDups(:, 2);

            if obj.self_referenced
                x = xPoints;
                y = yPoints;
            else
                transform = obj.tform;
                [x, y] = transformPointsForward(transform, xPoints, yPoints);
            end
            obj.Target = [x, y];
            closed = true;
            obj.roi_meta.x = x;
            obj.roi_meta.y = y;

            if obj.fixed_rep_rate_flag
                obj.framerate_to_microns_per_point(obj.frame_rate);
            end

            resampled_points = resample_curve([x, y], obj.Points_Per_Volt, closed, false);
            obj.Project_Spots(resampled_points(:, 1), resampled_points(:, 2));
        end

        function genPoints(obj, xPoints, yPoints, options)
            arguments
                obj Scanning_Device
                xPoints
                yPoints
                options.dwell_time = 0.1
            end

            xPoints = double(obj.refimage.xdata(xPoints));
            yPoints = double(obj.refimage.ydata(yPoints));

            if ~obj.self_referenced
                transform = obj.tform;
                [xPoints, yPoints] = transformPointsForward(transform, xPoints, yPoints);
            end

            obj.Project_Spots(xPoints', yPoints', 'dwell_time', options.dwell_time);
        end

        function Load_Ref_Im_JS(obj, filename)
            Load_Ref_Im_JS@Patterning_Device(obj, filename);

            if strcmp(obj.refimage.type, 'Confocal_Device') && strcmp(obj.refimage.name, obj.name)
                obj.self_referenced = true;
            else
                obj.self_referenced = false;
            end
        end

        %% Get data

        % we need to turn point clouds into images
        % frames has dimensions [x,y,frame]
        function frames = getAcquiredFrames(obj)
            % if we have no output data, throw an error
            if isempty(obj.outputdata)
                error('No output data to get frames from');
            end

            outputdata = obj.outputdata;
            nwfm = numel(obj.galvox_wfm);
            [x, y] = transformPointsInverse(obj.tform, [0 1], [0 1]);
            dims = [x; y];
            points_per_volt = round(sqrt(nwfm / ((max(outputdata.galvofbx) - min(outputdata.galvofbx)) * (max(outputdata.galvofby) - min(outputdata.galvofby)))));
            pixels_per_volt = sqrt(sum((dims(:, 1) - dims(:, 2)) .^ 2)) / sqrt(2) / obj.feedback_scaling;
            microns_per_volt = pixels_per_volt * obj.MICRONS_PER_CAMERA_PIXEL;
            nom_res = microns_per_volt / points_per_volt;
            xdata = reshape((outputdata.galvofbx - min(outputdata.galvofbx)) * microns_per_volt, nwfm, []);
            ydata = reshape((outputdata.galvofby - min(outputdata.galvofby)) * microns_per_volt, nwfm, []);
            PMT_dat = reshape(outputdata.PMT, nwfm, []);
            xvec = min(xdata(:)):nom_res:max(xdata(:));
            yvec = min(ydata(:)):nom_res:max(ydata(:));
            [xq, yq] = meshgrid(xvec, yvec);
            frames = zeros(numel(yvec), numel(xvec), size(xdata, 2));

            % interpolate data to fit the grid
            for i = 1:size(xdata, 2)
                F = scatteredInterpolant(xdata(:, i), ydata(:, i), PMT_dat(:, i), 'linear', 'nearest');
                frames(:, :, i) = F(xq, yq);
            end

            if size(frames, 3) == 1 % 1 frame
                galvofboffset = mean(outputdata.galvofby / obj.feedback_scaling - outputdata.galvoy_wfm);
                xout = (xvec / microns_per_volt + min(outputdata.galvofbx)) / obj.feedback_scaling - galvofboffset;
                yout = (yvec / microns_per_volt + min(outputdata.galvofby)) / obj.feedback_scaling - galvofboffset;
            end
        end
    end
end
