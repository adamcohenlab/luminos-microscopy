function stackImgs = RoundRobin_ext_ramp_PV(inputStacks, holdings, blank2rampT_ratio, rampStepNum, num_repeat)
inputStacks = logical(inputStacks);
n_rois = size(inputStacks, 3);
DMD_height = 1024;
DMD_width = 768;
%set the default values

blank2ramp = 0.5;
%rampStepN=5;
repeats = 1;
% assign the values
if exist('holdings', 'var')
    roiHolding = holdings;
end
if exist('plank2rampT_ratio', 'var')
    blank2ramp = blank2rampT_ratio;
end
blankSamps = round(blank2ramp*rampStepN);
if exist('rampStepNum', 'var')
    rampStepN = rampStepNum;
end
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
    img = inputStacks(:, :, i);
    imrampUp = imramp(img, rampStepN, 'up');
    imrampDown = imramp(img, rampStepN, 'down');

    roiStackImgs = cat(3, roiStackImgs, repmat(zeros(DMD_height, DMD_width), [1, 1, blankSamps]));
    roiStackImgs = cat(3, roiStackImgs, imrampUp);
    roiStackImgs = cat(3, roiStackImgs, imrampDown);
    stackImgs = cat(3, stackImgs, roiStackImgs);
end
imgAll = sum(inputStacks, 3);
imgAllrampUp = imramp(imgAll, rampStepN, 'up');
%imgAllrampDown=imramp(imgAll,rampStepN,'down');
stackImgs = cat(3, stackImgs, repmat(zeros(DMD_height, DMD_width), [1, 1, blankSamps]));
stackImgs = cat(3, stackImgs, imgAllrampUp);
%stackImgs=cat(3,stackImgs,imgAllrampDown);
stackImgs = cat(3, stackImgs, repmat(zeros(DMD_height, DMD_width), [1, 1, blankSamps]));
stackImgs = repmat(stackImgs, [1, 1, repeats]);
stackImgs = cat(3, zeros(DMD_height, DMD_width), stackImgs);
stackImgs = logical(stackImgs);

end
