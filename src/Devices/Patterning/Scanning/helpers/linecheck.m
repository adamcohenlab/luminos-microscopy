function R = linecheck(p1, p2, testpoints)
m = (p2(2) - p1(2)) / (p2(1) - p1(1)); %Compute slope between two points
yvec = (testpoints(:, 1) - p1(1)) * m;
if p1(1) < p2(1)
    R = yvec < 1 & (testpoints(:, 1) > p1(1) & testpoints(:, 1) < p2(1));
else
    R = yvec < 1 & (testpoints(:, 1) < p1(1) & testpoints(:, 1) > p2(1));
end
end