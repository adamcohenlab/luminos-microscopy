function stackImgs = addPieSlices(img, num_slices, num_repeat, mode, InDiam, OutDiam, x_Center, y_Center)
cellImg = logical(img);
stats = regionprops(cellImg);
centroid = stats.Centroid;
cellImg = double(cellImg);
DMD_height = 1024;
DMD_width = 768;
%set the default values
n = 12;
repeats = 1;
xCenter = round(centroid(2));
yCenter = round(centroid(1));
OutD = min(DMD_width-yCenter, yCenter);
InD = 150;
% assign the specified values
if exist('num_slices', 'var')
    n = num_slices;
end

if exist('num_repeat', 'var')
    repeats = num_repeat;
end
if exist('InDiam', 'var')
    InD = InDiam;
end
if exist('OutDiam', 'var')
    outD = OutDiam;
end
if exist('x_Center', 'var')
    xCenter = x_Center;
end
if exist('y_Center', 'var')
    yCenter = y_Center;
end


angleMap = zeros(DMD_height, DMD_width);
for i = 1:DMD_height
    for j = 1:DMD_width
        d = ((i - xCenter)^2 + (j - yCenter)^2)^0.5;
        if i - xCenter < 0 %(pi:3/2*pi)
            angle = 180 - asind((j - yCenter)/d);
        else
            if j - yCenter >= 0 %(0:pi/2)
                angle = asind((j - yCenter)/d);
            else %(3/2*pi:2pi)
                angle = 360 + asind((j - yCenter)/d);
            end
        end
        angleMap(i, j) = angle;
    end
end


sliceImg = zeros(DMD_height, DMD_width, n);
for a = 1:n
    angle1 = (a - 1) * 360 / n;
    angle2 = angle1 + 360 / n;
    for i = 1:DMD_height
        for j = 1:DMD_width
            d = ((i - xCenter)^2 + (j - yCenter)^2)^0.5;
            if d > InD && d <= OutD && angleMap(i, j) >= angle1 && angleMap(i, j) < angle2
                sliceImg(i, j, a) = 1;

            end
        end
    end
end

if isempty(find(strcmp(mode, 'interleaved'))) == 0
    nPulse = 6;
    stackImgs = zeros(DMD_height, DMD_width, nPulse*n);
    for b = 1:n
        stackImgs(:, :, nPulse*(b - 1)+1) = cellImg;
        stackImgs(:, :, nPulse*(b - 1)+2) = cellImg + sliceImg(:, :, b);
        stackImgs(:, :, nPulse*(b - 1)+3) = cellImg;
        stackImgs(:, :, nPulse*(b - 1)+5) = sliceImg(:, :, b);

    end
elseif isempty(find(strcmp(mode, 'continuous'))) == 0
    nPulse = 4;
    stackImgs = zeros(DMD_height, DMD_width, nPulse*n*2+1);
    for b = 1:n
        stackImgs(:, :, nPulse*(b - 1)+1) = cellImg;
        stackImgs(:, :, nPulse*(b - 1)+2) = cellImg + sliceImg(:, :, b);
        stackImgs(:, :, nPulse*(b - 1)+3) = cellImg;
    end
    for b = 1:n
        stackImgs(:, :, nPulse*(b - 1)+3+nPulse*n+1) = sliceImg(:, :, b);
    end

elseif isempty(find(strcmp(mode, 'control off'))) == 0
    nPulse = 4;
    stackImgs = zeros(DMD_height, DMD_width, nPulse*n);
    for b = 1:n
        stackImgs(:, :, nPulse*(b - 1)+1) = cellImg;
        stackImgs(:, :, nPulse*(b - 1)+2) = cellImg + sliceImg(:, :, b);
        stackImgs(:, :, nPulse*(b - 1)+3) = cellImg;

    end
end


stackImgs = repmat(stackImgs, [1, 1, repeats]);
stackImgs = cat(3, zeros(DMD_height, DMD_width), stackImgs);
stackImgs = logical(stackImgs);
end
