function [sequence, coords] = quarter(obj, quarterindex)
%  Sets all pixels to maximum value in specified quarter
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
    sequence = quarterframe(obj.height, obj.width, quarterindex);
    if nargout >= 2
        coords = quartercoords(obj.height, obj.width, quarterindex);
    end
    return;
end

obj.put(quarterframe(obj.height, obj.width, quarterindex));

end


function frame = quarterframe(height, width, quarterindex)
frame = zeros(height, width, 'uint8');
hheight = ceil(height/2);
hwidth = ceil(width/2);
switch quarterindex
    case 1
        frame(1:hheight, 1:hwidth) = uint8(255);
    case 2
        frame(1:hheight, hwidth+1:width) = uint8(255);
    case 3
        frame(hheight+1:height, 1:hwidth) = uint8(255);
    otherwise
        frame(hheight+1:height, hwidth+1:width) = uint8(255);
end
end

function coords = quartercoords(height, width, quarterindex)
hheight = ceil(height/2);
hwidth = ceil(width/2);
switch quarterindex
    case 1
        coords = [1, 1; hheight, 1; hheight, hwidth; 1, hwidth];
    case 2
        coords = [1, hwidth + 1; hheight, hwidth + 1; hheight, width; 1, width];
    case 3
        coords = [hheight + 1, 1; height, 1; height, hwidth; hheight + 1, hwidth];
    otherwise
        coords = [hheight + 1, hwidth + 1; height, hwidth + 1; height, width; hheight + 1, width];
end
end