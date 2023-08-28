function pathout = linesfrompoints(points, sampling_density)
pathout = []; %FUTURE IMPROVEMENT: SMART PREALLOCATION IF SPEED IS AN ISSUE
for i = 2:size(points, 1)
    dist = sqrt((points(i, 2) - points(i-1, 2))^2+(points(i, 1) - points(i-1, 1))^2);
    numpoints = round(sampling_density*dist);
    m = (points(i, 2) - points(i-1, 2)) / (points(i, 1) - points(i-1, 1));
    xsamps = linspace(points(i-1, 1), points(i, 1), numpoints);
    if isfinite(m)
        pathout = vertcat(pathout, [xsamps', (m * (xsamps - points(i-1, 1)) + points(i-1, 2))']);
    else
        pathout = vertcat(pathout, [xsamps', linspace(points(i-1, 2), points(i, 2), numpoints)']);
    end
end
end
