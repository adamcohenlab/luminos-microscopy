function stackImgs = conn_map_pulse(inputStacks, maxHoldings, num_pulse, holdingSteps, holding2pulse_ratio, num_repeat, blank2holdingT_ratio)
inputStacks = logical(inputStacks);
n_rois = size(inputStacks, 3);
DMD_height = 1024;
DMD_width = 768;
%set the default values
Holdings = 0.2 * ones(1, n_rois);
pulseN = 10;
holdingStepsN = 4;
repeats = 1;
blank2Holding = 0.25;
% assuming each pulse =20 ms; recovery period = 200 ms;
holding2pulse = 10;
% assign the values
if exist('maxHoldings', 'var')
    Holdings = maxHoldings;
end
if exist('num_pulse', 'var')
    pulseN = num_pulse;
end
if exist('holdingSteps', 'var')
    holdingStepsN = holdingSteps;
end
if exist('holding2pulse_ratio', 'var')
    holding2pulse = holding2pulse_ratio;
end

if exist('num_repeat', 'var')
    repeats = num_repeat;
end
if exist('blank2holdingT_ratio', 'var')
    blank2Holding = blank2holdingT_ratio;
end
% generate holding masks for each roi
imgHoldings = zeros(size(inputStacks));
for i = 1:n_rois
    img = inputStacks(:, :, i);
    idx = find(img == 1);
    randIdx = randperm(length(idx), round(length(idx)*Holdings(i)));
    idxOn = idx(randIdx);
    idxOn(idxOn == 0) = [];
    fullmask = zeros(DMD_height, DMD_width);
    fullmask(idxOn) = 1;
    imgHoldings(:, :, i) = fullmask;
end
imgHoldingAll = sum(imgHoldings, 3);

stackImgs = [];

for i = 1:n_rois
    imgPulse = inputStacks(:, :, i);
    imgHoldingOthers = imgHoldingAll - imgPulse;
    imgHoldingOthers(imgHoldingOthers < 0) = 0;
    imgHoldingStep = imramp(imgHoldingOthers, holdingStepsN, 'up');

    blankSamps = round(blank2Holding*holding2pulse*pulseN*holdingStepsN);

    roiStackImgs = [];

    for j = 1:holdingStepsN
        pulseStackImgs = [];
        pulseStackImgs = cat(3, pulseStackImgs, repmat(imgHoldingStep(:, :, j), [1, 1, 2]));
        pulseStackImgs = cat(3, pulseStackImgs, imgHoldingStep(:, :, j)+imgPulse);
        pulseStackImgs = cat(3, pulseStackImgs, repmat(imgHoldingStep(:, :, j), [1, 1, (holding2pulse - 3)]));
        pulseStackImgs = repmat(pulseStackImgs, [1, 1, pulseN]);
        roiStackImgs = cat(3, roiStackImgs, pulseStackImgs);
    end

    stackImgs = cat(3, stackImgs, repmat(zeros(DMD_height, DMD_width), [1, 1, blankSamps]));
    stackImgs = cat(3, stackImgs, roiStackImgs);
end

stackImgs = repmat(stackImgs, [1, 1, repeats]);
stackImgs = logical(stackImgs);

end