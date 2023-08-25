function stackImgs = addDonutSeries(img, num_ring, num_repeat, mode, InDiam, OutDiam, x_Center, y_Center)
cellImg = logical(img);
stats = regionprops(cellImg);
centroid = stats.Centroid;
cellImg = double(cellImg);
DMD_height = 1024;
DMD_width = 768;
%set the default values
n = 1;
repeats = 1;
xCenter = round(centroid(2));
yCenter = round(centroid(1));
OutD = min(DMD_width-yCenter, yCenter);
InD = 150;
%
if exist('num_ring', 'var')
    n = num_ring;
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


donutImg = zeros(DMD_height, DMD_width, n);
ringWidth = floor((OutD - InD)/n);
In = InD;
for a = 1:n
    Out = In + ringWidth;
    if Out > OutD
        Out = OutD;
    end

    for i = 1:DMD_height
        for j = 1:DMD_width
            d = ((i - xCenter)^2 + (j - yCenter)^2)^0.5;
            if d > In && d <= Out
                donutImg(i, j, a) = 1;
            end
        end
    end
    In = In + ringWidth;
end


if isempty(find(strcmp(mode, 'interleaved'))) == 0
    nPulse = 6;
    stackImgs = zeros(DMD_height, DMD_width, nPulse*n);
    for b = 1:n
        stackImgs(:, :, nPulse*(b - 1)+1) = cellImg;
        stackImgs(:, :, nPulse*(b - 1)+2) = cellImg + donutImg(:, :, b);
        stackImgs(:, :, nPulse*(b - 1)+3) = cellImg;
        stackImgs(:, :, nPulse*(b - 1)+5) = donutImg(:, :, b);
    end
elseif isempty(find(strcmp(mode, 'continuous'))) == 0
    nPulse = 4;
    stackImgs = zeros(DMD_height, DMD_width, nPulse*n*2+1);
    for b = 1:n
        stackImgs(:, :, nPulse*(b - 1)+1) = cellImg;
        stackImgs(:, :, nPulse*(b - 1)+2) = cellImg + donutImg(:, :, b);
        stackImgs(:, :, nPulse*(b - 1)+3) = cellImg;
    end
    for b = 1:n
        stackImgs(:, :, nPulse*(b - 1)+2+nPulse*n+1) = donutImg(:, :, b);
    end
elseif isempty(find(strcmp(mode, 'control off'))) == 0
    nPulse = 4;
    stackImgs = zeros(DMD_height, DMD_width, nPulse*n);
    for b = 1:n
        stackImgs(:, :, nPulse*(b - 1)+1) = cellImg;
        stackImgs(:, :, nPulse*(b - 1)+2) = cellImg + donutImg(:, :, b);
        stackImgs(:, :, nPulse*(b - 1)+3) = cellImg;

    end
end


stackImgs = repmat(stackImgs, [1, 1, repeats]);
stackImgs = cat(3, zeros(DMD_height, DMD_width), stackImgs);
stackImgs = logical(stackImgs);

end
