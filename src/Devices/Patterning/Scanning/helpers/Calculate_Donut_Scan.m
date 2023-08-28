function [xwfm, ywfm] = Calculate_Donut_Scan(center, radius, rmin, points_per_volt)
pps = round(pi*radius^2*points_per_volt^2);
t = 0:pps - 1;
r = sqrt(t/(pi * points_per_volt^2));
theta = sqrt(4*pi*t);
rclipped = r(r > rmin);
thetaclipped = theta(r > rmin);
xwfm = rclipped .* cos(thetaclipped) + center(1);
ywfm = rclipped .* sin(thetaclipped) + center(2);
% figure
% plot(xwfm,ywfm)
end
