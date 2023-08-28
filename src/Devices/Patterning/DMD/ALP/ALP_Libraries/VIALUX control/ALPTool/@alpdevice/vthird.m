function [sequence, coords] = vthird(obj, thirdindex)
%  Sets all pixels to maximum value in specified third
%
%  See also:
%     on, half, third
%
%  File information:
%     version 1.0 (feb 2014)
%     (c) Martin Vogel
%     email: matlab@martin-vogel.info
%
%  Revision history:
%     1.0 (feb 2014) initial release version

if nargout >= 1
    sequence = vthirdframe(obj.height, obj.width, thirdindex);
    if nargout >= 2
        coords = vthirdcoords(obj.height, obj.width, thirdindex);
    end
    return;
end

obj.put(vthirdframe(obj.height, obj.width, thirdindex));

end


function frame = vthirdframe(height, width, thirdindex)
frame = zeros(height, width, 'uint8');
twidth = ceil(width/3);
twidth2 = twidth * 2;
switch thirdindex
    case 1
        frame(:, 1:twidth) = uint8(255);
    case 2
        frame(:, twidth+1:twidth2) = uint8(255);
    otherwise
        frame(:, twidth2+1:width) = uint8(255);
end
end

function coords = vthirdcoords(height, width, thirdindex)
twidth = ceil(width/3);
twidth2 = twidth * 2;
switch thirdindex
    case 1
        coords = [1, 1; height, 1; height, twidth; 1, twidth];
    case 2
        coords = [1, twidth + 1; height, twidth + 1; height, twidth2; 1, twidth2];
    otherwise
        coords = [1, twidth2 + 1; height, twidth2 + 1; height, width; 1, width];
end
end
