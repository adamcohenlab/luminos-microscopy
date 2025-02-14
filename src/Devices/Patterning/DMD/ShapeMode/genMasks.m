function tmasks = genMasks(dmd, varargin)

% Set scaling factor
if ~isempty(varargin)
    scaleFactor = varargin{1};
else
    scaleFactor = 1;
end

ShapeArray = dmd.shapes;

% Scale the radius if scaleFactor is not 1
if scaleFactor ~= 1
    for i = 1:length(ShapeArray.circles)
        ShapeArray.circles(i).radius = ShapeArray.circles(i).radius * scaleFactor;
    end
end

% Generate masks with scaled shapes
rmasks = fillShape(ShapeArray, dmd.refimage.ref2d.ImageSize);

for i = 1:size(rmasks,3)
    tmasks(:,:,i) = setPatterningROI(dmd, rmasks(:,:,i), write_when_complete = 0);
end

% If scaling factor is not 1, generate the last mask without scaling
if scaleFactor ~= 1
    % Restore original shapes for the last mask
    ShapeArray = dmd.shapes;  % Reset to original shapes
    rmasks_original = fillShape(ShapeArray, dmd.refimage.ref2d.ImageSize);
    rmask_original = imresize(rmasks_original, newSize);
    tmasks_original = setPatterningROI(dmd, rmask_original, 0);
    tmasks(:,:,size(tmasks,3)+1) = sum(tmasks_original, 3);
else
    % Sum the existing masks if no scaling
    tmasks(:,:,size(tmasks,3)+1) = sum(tmasks, 3);
end

%tmasks = ceil(tmasks); 

dmd.all_patterns = tmasks;
% Display and store results
figure; moviefixsc(tmasks,[0 1]);

% disp("Code for displaying:");
% disp("dmd.pattern_stack = masks;");
% disp("Write_Stack(dmd);");
end
