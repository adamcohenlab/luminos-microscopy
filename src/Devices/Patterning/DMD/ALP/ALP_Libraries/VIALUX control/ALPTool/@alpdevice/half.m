function [sequence, coords] = half(obj, halfindex)
%  Sets all pixels to maximum value in specified half
%   halfindex = 1 = upper half (large axis split in two)
%   halfindex = 2 = lower half (ditto)
%   halfindex = 3 = left half (small axis split in two)
%   halfindex = 4 = right half (ditto)
%
%  See also:
%     on, quarter
%
%  File information:
%     version 1.0 (feb 2014)
%     (c) Martin Vogel
%     email: matlab@martin-vogel.info
%
%  Revision history:
%     1.0 (feb 2014) initial release version

if nargout >= 1
    sequence = halfframe(obj.height, obj.width, halfindex);
    if nargout >= 2
        coords = halfcoords(obj.height, obj.width, halfindex);
    end
    return;
end

obj.put(halfframe(obj.height, obj.width, halfindex));

end

function frame = halfframe(height, width, halfindex)
frame = zeros(height, 768, 'uint8');
hheight = ceil(height/2);
hwidth = ceil(width/2);
switch halfindex
    case 1
        frame(1:hheight, :) = uint8(255);
    case 2
        frame(hheight+1:height, :) = uint8(255);
    case 3
        frame(:, 1:hwidth) = uint8(255);
    otherwise
        frame(:, hwidth+1:width) = uint8(255);
end
end

function coords = halfcoords(height, width, halfindex)
hheight = ceil(height/2);
hwidth = ceil(width/2);
switch halfindex
    case 1
        coords = [1, 1; hheight, 1; hheight, width; 1, width];
    case 2
        coords = [hheight + 1, 1; height, 1; height, width; hheight + 1, width];
    case 3
        coords = [1, 1; height, 1; height, hwidth; 1, hwidth];
    otherwise
        coords = [1, hwdith + 1; height, hwidth + 1; height, width; 1, width];
end
end