function [sequence, coords] = third(obj, thirdindex)
%  Sets all pixels to maximum value in specified third
%
%  See also:
%     on, half
%
%  File information:
%     version 1.0 (feb 2014)
%     (c) Martin Vogel
%     email: matlab@martin-vogel.info
%
%  Revision history:
%     1.0 (feb 2014) initial release version

if nargout >= 1
    sequence = thirdframe(obj.height, obj.width, thirdindex);
    if nargout >= 2
        coords = thirdcoords(obj.height, obj.width, thirdindex);
    end
    return;
end

obj.put(thirdframe(obj.height, obj.width, thirdindex));

end


function frame = thirdframe(height, width, thirdindex)
frame = zeros(height, width, 'uint8');
theight = ceil(height/3);
theight2 = theight * 2;
switch thirdindex
    case 1
        frame(1:theight, :) = uint8(255);
    case 2
        frame(theight+1:theight2, :) = uint8(255);
    otherwise
        frame(theight2+1:height, :) = uint8(255);
end
end

function coords = thirdcoords(height, width, thirdindex)
theight = ceil(height/3);
theight2 = theight * 2;
switch thirdindex
    case 1
        coords = [1, 1; theight, 1; theight, width; 1, width];
    case 2
        coords = [theight + 1, 1; theight2, 1; theight2, width; theight + 1, width];
    otherwise
        coords = [theight2 + 1, 1; height, 1; height, width; theight2 + 1, width];
end
end
