function stackImgs = RoundRobinExt(inputStack, varargin)

DMD_height = 1024;
DMD_width = 768;
%get additional input parameters (varargin)
if isempty(find(strcmp(varargin, 'interval'))) == 0
    nStacks = size(inputStack, 3) * 2;
    stackImgs = zeros(DMD_height, DMD_width, nStacks);
    for i = 1:size(inputStack, 3)
        stackImgs(:, :, (i - 1)*2+1) = inputStack(:, :, i);
    end
else
    stackImgs = inputStack;
end
stackImgs = cat(3, zeros(DMD_height, DMD_width), stackImgs);
stackImgs = logical(stackImgs);
end
