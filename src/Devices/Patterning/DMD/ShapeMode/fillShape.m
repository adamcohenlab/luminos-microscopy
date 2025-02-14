function masks = fillShape(shapes, size)
    % Check if input is an array of shapes or a single shape
    if iscell(shapes)
        numShapes = numel(shapes);
        masks = zeros([size, numShapes]); % Initialize the mask array
        maskIndex = 1;
        for i = 1:numShapes
            if ~isempty(shapes{i})
                masks(:, :, maskIndex) = generateMask(shapes{i}, size);
                maskIndex = maskIndex + 1;
            end
        end
        masks = masks(:, :, 1:maskIndex-1); % Trim unused mask layers if any
    elseif isstruct(shapes) && isfield(shapes, 'polygons') && isfield(shapes, 'circles')
        % Input is the shapesOutput structure
        numPolygons = numel(shapes.polygons);
        numCircles = numel(shapes.circles);
        masks = zeros([size]);
        
        % Process polygons
        maskIndex = 1;
        for i = 1:numPolygons
            if ~isempty(shapes.polygons{i})
                masks(:, :, maskIndex) = generateMask(shapes.polygons{i}, size);
                maskIndex = maskIndex + 1;
            end
        end
        
        % Process circles
        for i = 1:numCircles
            masks(:, :, maskIndex) = generateMask(shapes.circles(i), size);
            maskIndex = maskIndex + 1;
        end
    else
        % Input is a single shape
        masks = generateMask(shapes, size);
    end
end


function mask = generateMask(shape, size)
    mask = zeros(size); % Create a blank mask
    
    if isstruct(shape) && isfield(shape, 'center') && isfield(shape, 'radius')
        % Handle circle
        [X, Y] = meshgrid(1:size(2), 1:size(1));
        mask = (X - shape.center(1)).^2 + (Y - shape.center(2)).^2 <= shape.radius^2;
    elseif iscell(shape) || ismatrix(shape)
        % Handle polygon
        vertices = shape;
        mask = poly2mask(vertices(:,1), vertices(:,2), size(1), size(2));
    else
        error('Unsupported shape type.');
    end
end
