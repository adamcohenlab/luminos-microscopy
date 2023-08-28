function stackImgs = hysteresis_donutRamp(img, rampStepNum, num_repeat, InDiam)
cellImg = logical(img);
stats = regionprops(cellImg);
centroid = stats.Centroid;
cellImg = double(cellImg);
DMD_height = 1024;
DMD_width = 768;
xCenter = round(centroid(2));
yCenter = round(centroid(1));

%set the default values
rampStepN = 10;
repeats = 1;
InD = 200;
OutD = min(DMD_width-yCenter, yCenter);
%
if exist('rampStepNum', 'var')
    rampStepN = rampStepNum;
end
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


donutRampUpImgs = imramp(donutImg, rampStepN, 'up');
donutRampDownImgs = imramp(donutImg, rampStepN, 'down');
stackImgs = zeros(DMD_height, DMD_width, 7+4*rampStepN);

stackImgs(:, :, 1) = cellImg;
stackImgs(:, :, 2:2+rampStepN) = donutRampDownImgs + cellImg;
stackImgs(:, :, 3+rampStepN:3+2*rampStepN) = donutRampUpImgs + cellImg;
stackImgs(:, :, 5+2*rampStepN) = donutImg(:, :);
stackImgs(:, :, 6+2*rampStepN:6+3*rampStepN) = donutRampDownImgs + cellImg;
stackImgs(:, :, 7+3*rampStepN:7+4*rampStepN) = donutRampUpImgs + cellImg;


stackImgs = repmat(stackImgs, [1, 1, repeats]);
stackImgs = cat(3, zeros(DMD_height, DMD_width), stackImgs);
stackImgs = logical(stackImgs);

end
