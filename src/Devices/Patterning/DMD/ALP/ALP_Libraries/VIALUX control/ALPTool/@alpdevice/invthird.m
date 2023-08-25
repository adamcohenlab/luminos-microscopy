function [sequence, coords] = invthird(obj, thirdindex)
%  Sets all pixels to minimum value in specified third
%
%  See also:
%     third, on, half
%
%  File information:
%     version 1.0 (feb 2014)
%     (c) Martin Vogel
%     email: matlab@martin-vogel.info
%
%  Revision history:
%     1.0 (feb 2014) initial release version

if nargout >= 1
    [s, c] = obj.third(thirdindex);
    sequence = obj.on() - s;
    if nargout >= 2
        coords = c;
    end
    return;
end

obj.put(obj.on()-obj.third(thirdindex));

end
