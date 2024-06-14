classdef Trap_Device < Patterning_Device
    properties (Transient)
        app Rig_Control_App
        dq DAQ
        current_voltage
        current_pixel
        theta
        distance
    end
    properties
        galvox_phys_channel
        galvoy_phys_channel
        calvoltage
        x_lim
        y_lim
        minstep
        volts_per_pixel
    end
    methods
        % trap position control
        function Update_Galvos_On_Demand(obj, galvox_val, galvoy_val)
            arguments
                obj
                galvox_val
                galvoy_val
            end
            DQ_AO_On_Demand(galvox_val, obj.galvox_phys_channel); % change this to buffered task
            DQ_AO_On_Demand(galvoy_val, obj.galvoy_phys_channel);
            obj.current_voltage = [galvox_val, galvoy_val];
            obj.current_pixel = round(transformPointsInverse(obj.tform, obj.current_voltage));
        end
        function Measure_Angle(obj)
            % measure angle about which to apply wfm
            line = drawline(obj.tax);
            obj.theta = atan2d(line.Position(2, 2)-line.Position(1, 2), line.Position(2, 1)-line.Position(1, 1));
        end
        function Measure_Distance(obj)
            % measure a distance on ref img and convert to voltage (this
            % could be used for an amplitude, radius, etc.)
            line = drawline(obj.tax);
            obj.distance = sqrt((line.Position(2, 2) - line.Position(1, 2))^2+(line.Position(2, 1) - line.Position(1, 1))^2) * obj.volts_per_pixel;
        end
        function Move_On_Demand(obj)
            roi = drawpoint(obj.tax);
            voltage_toApply = transformPointsForward(obj.tform, roi.Position);
            obj.Update_Galvos_On_Demand(voltage_toApply(1), voltage_toApply(2));
        end
        % image registration methods
        function Project_Cal_Pattern(obj)
            xpoints = repmat(obj.calvoltage(:, 1)', [1, 1e3]);
            ypoints = repmat(obj.calvoltage(:, 2)', [1, 1e3]);
            for i = 1:numel(xpoints) % build in enough time to capture snap through solis software
                obj.Update_Galvos_On_Demand(xpoints(i), ypoints(i));
            end
            
        end
        function Cal_TForm(obj) % near copy of procedure for Scanning_Device
            Width = .1;
            [X, Y] = meshgrid(obj.x_lim(1):obj.minstep:obj.x_lim(2), obj.y_lim(1):obj.minstep:obj.y_lim(2));
            gauss = @(x0, y0, w0) exp(-((X - x0).^2 + (Y - y0).^2)/w0.^2);
            Target = zeros(size(X));
            for i = 1:size(obj.calvoltage, 1)
                Target = Target + gauss(obj.calvoltage(i, 1), obj.calvoltage(i, 2), Width);
            end
            for i = 1:size(obj.calvoltage, 1)
                [row, col] = find(abs(X-obj.calvoltage(i, 1)) < 1e-6 & abs(Y-obj.calvoltage(i, 2)) < 1e-6);
                matcoord(i, :) = [row, col];
            end
            im2volts_t = estimateGeometricTransform([matcoord(:, 2), matcoord(:, 1)], obj.calvoltage, 'affine');
            for i = 1:size(obj.calvoltage, 1)
                roi = drawpoint(obj.tax);
                registered_points(i, :) = roi.Position;
            end
            if isMATLABReleaseOlderThan("R2022b")
                [t_est, ~, ~, status] = estimateGeometricTransform(registered_points, [matcoord(:, 2), matcoord(:, 1)], ...
                'affine'); %old pre-R2022b convention
            else
                t_est = estgeotform2d(registered_points, [matcoord(:, 2), matcoord(:, 1)], ...
                'affine'); %new premultiply convention
            end
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
            obj.volts_per_pixel = sqrt(sum((obj.calvoltage(1, :) - obj.calvoltage(end, :)).^2)/sum((transformPointsInverse(obj.tform, obj.calvoltage(1, :)) - transformPointsInverse(obj.tform, obj.calvoltage(end, :))).^2));
        end
    end
end
