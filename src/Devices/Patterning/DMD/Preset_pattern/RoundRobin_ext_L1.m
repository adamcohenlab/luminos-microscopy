function stackImgs = RoundRobin_ext_L1(inputStacks, holdings, blank2rampT_ratio, num_repeat)
inputStacks = logical(inputStacks);
n_rois = size(inputStacks, 3);
DMD_height = 1024;
DMD_width = 768;
%set the default values
roiHolding = 0.4 * ones(1, n_rois);
blank2ramp = 19;
%rampStepN=5;
repeats = 1;
% assign the values
if exist('holdings', 'var')
    roiHolding = holdings;
end
if exist('plank2rampT_ratio', 'var')
    blank2ramp = blank2rampT_ratio;
end
blankSamps = round(blank2ramp);

if exist('num_repeat', 'var')
    repeats = num_repeat;
end

imgHolding = zeros(size(inputStacks));
for i = 1:n_rois
    idx = find(inputStacks(:, :, i) == 1);
    onPixelN = floor(length(idx)*roiHolding(i));
    if onPixelN == 0
        fullmask = zeros(DMD_height, DMD_width);
    else
        randIdx = randperm(length(idx), onPixelN);
        idxOn = idx(randIdx);
        idxOn(idxOn == 0) = [];
        fullmask = zeros(DMD_height, DMD_width);
        fullmask(idxOn) = 1;
    end
    imgHolding(:, :, i) = fullmask;
end

stackImgs = [];

for i = 1:n_rois
    roiStackImgs = [];
    roiStackImgs = cat(3, roiStackImgs, repmat(zeros(DMD_height, DMD_width), [1, 1, blankSamps]));
    roiStackImgs = cat(3, roiStackImgs, imgHoldings(:, :, i));
    stackImgs = cat(3, stackImgs, roiStackImgs);
end
imgAll = sum(imgHoldings, 3);
stackImgs = cat(3, stackImgs, repmat(zeros(DMD_height, DMD_width), [1, 1, blankSamps]));
stackImgs = cat(3, stackImgs, imgAll);
stackImgs = cat(3, stackImgs, repmat(zeros(DMD_height, DMD_width), [1, 1, blankSamps]));
stackImgs = repmat(stackImgs, [1, 1, repeats]);
stackImgs = cat(3, zeros(DMD_height, DMD_width), stackImgs);
stackImgs = logical(stackImgs);

end
