function stackImgs = RoundRobin(inputStack, mode, InhRatio, Interval)
% default
ratio = 0.1;
if exist('InhRatio', 'var')
    ratio = InhRatio;
end

DMD_height = 1024;
DMD_width = 768;

if isempty(find(strcmp(mode, 'inh'))) == 0
    inhMask = zeros(size(inputStack));
    inputStack = double(inputStack);
    for i = 1:size(inputStack, 3)
        stats1 = regionprops(inputStack(:, :, i));
        centroid1 = stats1.Centroid;
        smallMask = imresize(inputStack(:, :, i), (ratio)^0.5);
        smallMask(smallMask >= 0.5) = 1;
        smallMask(smallMask < 0.5) = 0;
        fullMask = zeros(DMD_height, DMD_width);
        fullMask(1:size(smallMask, 1), 1:size(smallMask, 2)) = smallMask;
        stats2 = regionprops(fullMask);
        centroid2 = stats2.Centroid;
        inhMask(:, :, i) = imtranslate(fullMask, round(centroid1-centroid2));
    end
    avgInhMask = sum(inhMask, 3);

    if isempty(find(strcmp(varargin, 'interval'))) == 0
        nStacks = size(inputStack, 3) * 2;
        stackImgs = zeros(DMD_height, DMD_width, nStacks);
        for i = 1:size(inputStack, 3)
            stackImgs(:, :, (i - 1)*2+1) = avgInhMask + inputStack(:, :, i);
        end
    else
        for i = 1:size(inputStack, 3)
            stackImgs(:, :, i) = avgInhMask + inputStack(:, :, i);
        end
    end

elseif isempty(find(strcmp(mode, 'ex'))) == 0
    if isempty(find(strcmp(varargin, 'interval'))) == 0
        nStacks = size(inputStack, 3) * 2;
        stackImgs = zeros(DMD_height, DMD_width, nStacks);
        for i = 1:size(inputStack, 3)
            stackImgs(:, :, (i - 1)*2+1) = inputStack(:, :, i);
        end
    else
        stackImgs = inputStack;
    end
else
    msg1 = 'specify ext or inh mask!'
    error(msg1);
end
stackImgs = cat(3, zeros(DMD_height, DMD_width), stackImgs);
stackImgs = logical(stackImgs);
end
