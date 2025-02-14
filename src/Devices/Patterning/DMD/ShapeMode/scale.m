function scaledShape = scale(shape, factor)
    if isa(shape, 'ShapeStack')
        % Handle stack
        for i = 1:numel(shape.Stack)
            shape.Stack{i} = scale(shape.Stack{i}, factor);
        end
        scaledShape = shape;
    else
        % Handle individual shape
        switch shape.Type
            case 'Polygon'
                com = mean(shape.Vertices, 1);
                shape.Vertices = bsxfun(@minus, shape.Vertices, com) * factor + com;
            case 'Circle'
                % Scale the radius, keep the center same
                shape.Radius = shape.Radius * factor;
            case 'Freeform'
                com = mean(shape.Curve, 1);
                shape.Curve = bsxfun(@minus, shape.Curve, com) * factor + com;
            otherwise
                error('Unsupported shape type');
        end
        scaledShape = shape;
    end
end
