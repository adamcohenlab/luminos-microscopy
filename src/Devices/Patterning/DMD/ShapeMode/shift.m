function shiftedShapes = shift(shapes, x, y)
    % Check if the shift is provided as a single two-element vector
    if nargin == 2
        if length(x) == 2
            y = x(2);
            x = x(1);
        else
            error('If providing a single input, it must be a two-element vector [x, y].');
        end
    elseif nargin ~= 3
        error('Incorrect number of input arguments. Provide either (shapes, [x, y]) or (shapes, x, y).');
    end
    
    if iscell(shapes)
        % Input is a cell array of shapes (e.g., polygons)
        shiftedShapes = cell(size(shapes));
        for i = 1:numel(shapes)
            shiftedShapes{i} = shiftSingleShape(shapes{i}, x, y);
        end
    elseif isstruct(shapes) && isfield(shapes, 'polygons') && isfield(shapes, 'circles')
        % Input is the shapesOutput structure
        numPolygons = numel(shapes.polygons);
        numCircles = numel(shapes.circles);
        shiftedShapes = struct('polygons', {{}}, 'circles', struct('center', {}, 'radius', {}));
        
        % Process polygons
        for i = 1:numPolygons
            shiftedShapes.polygons{i} = shiftSingleShape(shapes.polygons{i}, x, y);
        end
        
        % Process circles
        for i = 1:numCircles
            shiftedCircle = shiftSingleShape(shapes.circles(i), x, y);
            shiftedShapes.circles(i).center = shiftedCircle.center;
            shiftedShapes.circles(i).radius = shiftedCircle.radius;
        end
    else
        % Input is a single shape (e.g., polygon or circle)
        shiftedShapes = shiftSingleShape(shapes, x, y);
    end
end

function shiftedShape = shiftSingleShape(shape, x, y)
    % Check if shape is a circle or a polygon
    if isstruct(shape) && isfield(shape, 'center') && isfield(shape, 'radius')
        % Handle circle
        shape.center = shape.center + [x; y];
        shiftedShape = shape;
    elseif ismatrix(shape)
        % Handle polygon
        shape = shape + [x, y];
        shiftedShape = shape;
    else
        error('Unsupported shape type or format.');
    end
end

