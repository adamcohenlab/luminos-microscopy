function rampImgs = imramp(img, num_steps, mode)
img = logical(img);
idx = find(img == 1);
[nrow, ncol] = size(img);
step = 1 / num_steps;

rampImgs = zeros(nrow, ncol, num_steps);

if isempty(find(strcmp(mode, 'up'))) == 0
    for i = 1:num_steps
        randIdx = randperm(length(idx), round(length(idx)*step*i));
        idxOn = idx(randIdx);
        idxOn(idxOn == 0) = [];
        fullblack = zeros(nrow, ncol);
        fullblack(idxOn) = 1;
        rampImgs(:, :, i) = fullblack;
    end

elseif isempty(find(strcmp(mode, 'down'))) == 0
    for i = 1:num_steps
        randIdx = randperm(length(idx), round(length(idx)*step*(i - 1)));
        idxOff = idx(randIdx);
        idxOff(idxOff == 0) = [];
        fullblack = zeros(nrow, ncol);
        fullblack(idxOff) = 1;
        rampImgs(:, :, i) = img - fullblack;
    end
end
rampImgs = logical(rampImgs);
end