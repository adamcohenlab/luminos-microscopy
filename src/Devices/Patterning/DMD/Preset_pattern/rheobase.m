function StackImgs = rheobase(inputImg, blank2rampT_ratio, rampStepNum, num_repeat)
img = logical(inputImg);
DMD_height = 1024;
DMD_width = 768;
%set the default values
blank2ramp = 0.5;
rampStepN = 10;
repeats = 4;
% assign the values
if exist('blank2rampT_ratio', 'var')
    plat2ramp = plat2rampT_ratio;
end
if exist('rampStepNum', 'var')
    rampStepN = rampStepNum;
end
if exist('num_repeat', 'var')
    repeats = num_repeat;
end


StackImgs = [];
blankSamps = round(blank2ramp*rampStepN);
StackImgs = cat(3, StackImgs, repmat(zeros(DMD_height, DMD_width), [1, 1, blankSamps]));
imrampUp = imramp(img, rampStepN, 'up');
StackImgs = cat(3, StackImgs, imrampUp);
%StackImgs=cat(3,StackImgs,repmat(zeros(DMD_height, DMD_width),[1,1,blankSamps]));


StackImgs = repmat(StackImgs, [1, 1, repeats]);
StackImgs = cat(3, zeros(DMD_height, DMD_width), StackImgs);
StackImgs = cat(3, StackImgs, zeros(DMD_height, DMD_width));
StackImgs = logical(StackImgs);

end
