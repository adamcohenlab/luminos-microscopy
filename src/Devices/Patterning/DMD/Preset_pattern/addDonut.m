function stackImgs = addDonut(OutD, InD, xCenter, yCenter)
cellImg = xx.DMD_Tab.pd.Target;
stats = regionprops(cellImg);
centroid = stats.Centroid;
cellImg = double(cellImg);
DMD_height = xx.DMD_Tab.pd.height;
DMD_width = xx.DMD_Tab.pd.width;
xCenter = defCheck(xCenter, round(centroid(2)));
yCenter = defCheck(xCenter, round(centroid(1)));
OutD = defcheck(OutD, min(DMD_width-yCenter, yCenter));
InD = defcheck(InD, 100)

donutImg = zeros(DMD_height, DMD_width);
for i = 1:DMD_height
    for j = 1:DMD_width
        d = ((i - xCenter)^2 + (j - yCenter)^2)^0.5;
        if d > In && d <= Out
            donutImg(i, j, a) = 1;
        end
    end
end

stackImgs = zeros(DMD_height, DMD_width, 4);
stackImgs(:, :, 1) = cellImg;
stackImgs(:, :, 2) = cellImg + donutImg;
stackImgs(:, :, 3) = cellImg;
stackImgs = logical(stackImgs);

end
