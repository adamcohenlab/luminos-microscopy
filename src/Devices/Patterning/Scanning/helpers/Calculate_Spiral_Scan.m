function [xwfm, ywfm] = Calculate_Spiral_Scan(center, radius, points_per_volt)
pps = round(pi*radius^2*points_per_volt^2);
t = 0:pps - 1;
r = sqrt(t/(pi * points_per_volt^2));
theta = sqrt(4*pi*t);
xwfm = r .* cos(theta) + center(1);
ywfm = r .* sin(theta) + center(2);
end
