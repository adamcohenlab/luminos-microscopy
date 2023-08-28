function sequence = off(obj)
%  Sets all pixels to minimum value
%
%  See also:
%     on
%
%  File information:
%     version 1.0 (feb 2014)
%     (c) Martin Vogel
%     email: matlab@martin-vogel.info
%
%  Revision history:
%     1.0 (feb 2014) initial release version


if nargout >= 1
    % just return the frame
    sequence = poff(obj.height, obj.width);
    return;
end

obj.put(poff(obj.height, obj.width));

end


function frame = poff(height, width)
frame = zeros(height, width, 'uint8');
end
