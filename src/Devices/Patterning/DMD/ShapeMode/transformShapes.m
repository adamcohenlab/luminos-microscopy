function shapesOutput = transformShapes(shapesInput, tform)
    % Initialize the output structure
    shapesOutput = struct('polygons', {{}}, 'circles', []);
    
    % Transform polygons
    numPolygons = numel(shapesInput.polygons);
    for i = 1:numPolygons
        polygon = shapesInput.polygons{i};
        transformedPolygon = applyTformToPoints(polygon, tform);
        shapesOutput.polygons{i} = transformedPolygon;
    end
    
    % Transform circles
    numCircles = numel(shapesInput.circles);
    for i = 1:numCircles
        circle = shapesInput.circles(i);
        transformedCenter = applyTformToPoints(circle.center', tform);
        scalingFactor = meanScalingFactor(tform);
        transformedRadius = circle.radius * scalingFactor;
        shapesOutput.circles(i).center = transformedCenter';
        shapesOutput.circles(i).radius = transformedRadius;
    end
end

function transformedPoints = applyTformToPoints(points, tform)
    % Apply the transformation to each point
    % Check if tform is a structure or object to cover different types
    if isobject(tform) && ismethod(tform, 'transformPointsForward')
        % Assuming affine transformation object with method transformPointsForward
        transformedPoints = transformPointsForward(tform, points);
    elseif isstruct(tform) && isfield(tform, 'T')
        % Assuming tform as a structure containing a transformation matrix 'T'
        % Apply homogeneous transformation
        numPoints = size(points, 1);
        pointsHomogeneous = [points, ones(numPoints, 1)];
        transformedPointsHomogeneous = pointsHomogeneous * tform.T';
        transformedPoints = transformedPointsHomogeneous(:, 1:2);
    else
        error('Unsupported transformation type. Provide a valid affine transformation object or structure.');
    end
end

function scalingFactor = meanScalingFactor(tform)
    % Calculate the mean scaling factor from the affine transformation
    if isobject(tform) && ismethod(tform, 'transformPointsForward')
        % Assuming affine transformation object with method transformPointsForward
        [~, S, ~] = affineDecomposition(tform.T);
    elseif isstruct(tform) && isfield(tform, 'T')
        % Assuming tform as a structure containing a transformation matrix 'T'
        [~, S, ~] = affineDecomposition(tform.T);
    else
        error('Unsupported transformation type. Provide a valid affine transformation object or structure.');
    end
    % Mean scaling factor is the average of the diagonal elements of the scaling matrix
    scalingFactor = mean(diag(S));
end

function [R, S, T] = affineDecomposition(T)
    % Decompose the affine transformation matrix T into rotation R, scaling S, and translation T
    A = T(1:2, 1:2);
    t = T(1:2, 3);
    [U, D, V] = svd(A);
    R = U * V';
    S = V * D * V';
    T = t;
end
