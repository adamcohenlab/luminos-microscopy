function seq = dmdWriteRegistrationSquares(api, device, filepath)
if isa(filepath, 'numeric')
    pts = filepath;
else
    pts = dlmread(filepath);
end
for i = 1:size(pts, 1)
    img((pts(i, 1) - 10):pts(i, 1), (pts(i, 2) - 10):pts(i, 2)) = 255;
    img(pts(i, 1):(pts(i, 1) + 10), pts(i, 2):(pts(i, 2) + 10)) = 255;
end
seq = dmdWriteStaticImage(api, device, img);
end