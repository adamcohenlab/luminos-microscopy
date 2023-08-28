function y = defcheck(x, default)
if isstring(x) || ischar(x)
    x = str2double(x);
end
if x == -Inf || isnan(x)
    y = default;
else
    y = x;
end
end