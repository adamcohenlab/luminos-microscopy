%Use linear interpolation to resample an arbitrary curve into a set of
%evenly-spaced points. points should be an array of row vectors with
%each row representing one point in ND space. Closed is a boolean
%argument indicating whether the curve is closed or not (open).
%The meaning of N depends on the value of the resample_to_fixed_N flag. If
%the flag is false, then N is the desired point density, while if the flag
%is true, N is the desired total number of points.
function points_even = resample_curve(points, N, closed, resample_to_fixed_N)
if closed
    points(end+1, :) = points(1, :);
end
%Find linear distance between each sequential pair of points.
distances = vecnorm(points-circshift(points, -1), 2, 2);
distances = distances(1:end-1);
%Create 'time' vector used for interpolation.
t = [0; cumsum(distances)];
total_distance = t(end);
if ~resample_to_fixed_N
    n_points = round(N*total_distance);
else
    n_points = N;
end
if closed
    n_points = n_points + 1; %We will double-count the initial point.
end
%Linearly interpolate
points_even = interp1(t, points, linspace(0, total_distance, n_points));
%Remove duplicate starting/end point if closed.
if closed
    points_even = points_even(1:end-1, :);
end
end