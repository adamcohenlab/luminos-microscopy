function stackImgs = hysteresis_2cell(img1, img2, rampStepNum, num_repeat)
img1 = logical(img1);
img2 = logical(img2);
DMD_height = 1024;
DMD_width = 768;
%set the default values
rampStepN = 10;
repeats = 1;

%
if exist('rampStepNum', 'var')
    rampStepN = rampStepNum;
end
if exist('num_repeat', 'var')
    repeats = num_repeat;
end

imrampUp1 = imramp(img1, rampStepN, 'up');
imrampDown1 = imramp(img1, rampStepN, 'down');
imrampUp2 = imramp(img2, rampStepN, 'up');
imrampDown2 = imramp(img2, rampStepN, 'down');

stackImgs = zeros(DMD_height, DMD_width, 2+8*rampStepN);
stackImgs(:, :, 1:rampStepN) = repmat(img1, [1, 1, rampStepN]);
stackImgs(:, :, 1+rampStepN:1+2*rampStepN) = img1 + imrampUp2;
stackImgs(:, :, 2+2*rampStepN:2+3*rampStepN) = img1 + imrampDown2;
stackImgs(:, :, 1+4*rampStepN:5*rampStepN) = repmat(img2, [1, 1, rampStepN]);
stackImgs(:, :, 1+5*rampStepN:1+6*rampStepN) = img2 + imrampUp1;
stackImgs(:, :, 2+6*rampStepN:2+7*rampStepN) = img2 + imrampDown1;


stackImgs = repmat(stackImgs, [1, 1, repeats]);
stackImgs = cat(3, zeros(DMD_height, DMD_width), stackImgs);
stackImgs = logical(stackImgs);

end
