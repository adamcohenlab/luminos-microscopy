function stackImgs = hysteresis(img, num_repeat, InDiam)
cellImg = logical(img);
stats = regionprops(cellImg);
centroid = stats.Centroid;
cellImg = double(cellImg);
DMD_height = 1024;
DMD_width = 768;
xCenter = round(centroid(2));
yCenter = round(centroid(1));

%set the default values
repeats = 1;
InD = 200;
OutD = min(DMD_width-yCenter, yCenter);
%

if exist('num_repeat', 'var')
    repeats = num_repeat;
end
if exist('InDiam', 'var')
    InD = InDiam;
end


donutImg = zeros(DMD_height, DMD_width);
for i = 1:DMD_height
    for j = 1:DMD_width
        d = ((i - xCenter)^2 + (j - yCenter)^2)^0.5;
        if d > InD && d <= OutD
            donutImg(i, j) = 1;
        end
    end
end

nPulse = 6;
stackImgs = zeros(DMD_height, DMD_width, nPulse);

stackImgs(:, :, 1) = cellImg;
stackImgs(:, :, 2) = donutImg(:, :) + cellImg;
stackImgs(:, :, 4) = donutImg(:, :);
stackImgs(:, :, 5) = donutImg(:, :) + cellImg;


stackImgs = repmat(stackImgs, [1, 1, repeats]);
stackImgs = cat(3, zeros(DMD_height, DMD_width), stackImgs);
stackImgs = logical(stackImgs);

end
