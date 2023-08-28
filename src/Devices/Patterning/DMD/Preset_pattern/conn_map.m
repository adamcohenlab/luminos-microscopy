function stackImgs = conn_map(inputStacks, holdings, holding2rampT_ratio, blank2rampT_ratio, rampStepNum, num_repeat)
inputStacks = logical(inputStacks);
n_rois = size(inputStacks, 3);
DMD_height = 1024;
DMD_width = 768;
%set the default values
roiHolding = ones(1, n_rois);
holding2ramp = 1;
blank2ramp = 1;
rampStepN = 20;
repeats = 1;
% assign the values
if exist('holdings', 'var')
    roiHolding = holdings;
end
if exist('holding2rampT_ratio', 'var')
    holding2ramp = holding2rampT_ratio;
end
if exist('blank2rampT_ratio', 'var')
    blank2ramp = blank2rampT_ratio;
end

if exist('rampStepNum', 'var')
    rampStepN = rampStepNum;
end
if exist('num_repeat', 'var')
    repeats = num_repeat;
end

% generate holding masks for each roi
imgHolding = zeros(size(inputStacks));
for i = 1:n_rois
    idx = find(inputStacks(:, :, i) == 1);
    randIdx = rand(size(idx)) <= roiHolding(i);
    idxOn = idx .* randIdx;
    idxOn(idxOn == 0) = [];
    fullmask = zeros(DMD_height, DMD_width);
    fullmask(idxOn) = 1;
    imgHolding(:, :, i) = fullmask;
end

stackImgs = [];

for i = 1:n_rois
    roiStackImgs = [];
    blankSamps = round(blank2ramp*rampStepN);
    roiStackImgs = cat(3, roiStackImgs, repmat(zeros(DMD_height, DMD_width), [1, 1, blankSamps]));
    img = inputStacks(:, :, i);
    imrampUp = imramp(img, rampStepN, 'up');
    imrampDown = imramp(img, rampStepN, 'down');
    imgHoldingOthers = sum(imgHolding, 3) - img;
    imgHoldingOthers(imgHoldingOthers < 0) = 0;
    holdingSamps = round(holding2ramp*rampStepN);
    roiStackImgs = cat(3, roiStackImgs, repmat(imgHoldingOthers, [1, 1, holdingSamps]));
    roiStackImgs = cat(3, roiStackImgs, imrampUp+imgHoldingOthers);
    roiStackImgs = cat(3, roiStackImgs, imrampDown+imgHoldingOthers);
    roiStackImgs = cat(3, roiStackImgs, repmat(imgHoldingOthers, [1, 1, holdingSamps]));
    stackImgs = cat(3, stackImgs, roiStackImgs);
end


stackImgs = repmat(stackImgs, [1, 1, repeats]);
stackImgs = cat(3, zeros(DMD_height, DMD_width), stackImgs);
stackImgs = logical(stackImgs);

end