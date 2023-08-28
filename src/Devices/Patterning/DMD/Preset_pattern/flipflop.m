function stackImgs = flipflop(inputStacks, holdings, off2OnRatio, num_repeat)
inputStacks = logical(inputStacks);
n_rois = size(inputStacks, 3);
DMD_height = 1024;
DMD_width = 768;
%set the default values
roiHolding = ones(1, n_rois);
off2On = 1;
repeats = 4;
% assign the values
if exist('holdings', 'var')
    roiHolding = holdings;
end

if exist('off2OnRatio', 'var')
    off2On = off2OnRatio;
end
if exist('num_repeat', 'var')
    repeats = num_repeat;
end

% generate holding masks for each roi
imgHolding = zeros(size(inputStacks));
for i = 1:n_rois
    idx = find(inputStacks(:, :, i) == 1);
    randIdx = randperm(length(idx), round(length(idx)*roiHolding(i)));
    idxOn = idx(randIdx);
    fullmask = zeros(DMD_height, DMD_width);
    fullmask(idxOn) = 1;
    imgHolding(:, :, i) = fullmask;
end

stackImgs = [];

for i = 1:n_rois
    roiStackImgs = [];
    imgAll = sum(imgHolding, 3);
    imgFirst = imgHolding(:, :, i);
    imgFirst(imgFirst < 0) = 0;
    roiStackImgs = cat(3, roiStackImgs, imgFirst);
    AllOnSamps = round(1/off2On);
    imgRest = imgAll - imgFirst;
    roiStackImgs = cat(3, roiStackImgs, repmat(imgAll, [1, 1, AllOnSamps]));
    roiStackImgs = cat(3, roiStackImgs, repmat(imgRest, [1, 1, AllOnSamps]));
    stackImgs = cat(3, stackImgs, roiStackImgs);
end

stackImgs = repmat(stackImgs, [1, 1, repeats]);
stackImgs = cat(3, zeros(DMD_height, DMD_width), stackImgs);
stackImgs = logical(stackImgs);

end