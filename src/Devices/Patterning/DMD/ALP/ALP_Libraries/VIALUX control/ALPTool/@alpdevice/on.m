function sequence = on(obj)
%  Sets all pixels to maximum value
%
%  See also:
%     off
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
    sequence = pon(obj.height, obj.width);
    return;
end

obj.put(pon(obj.height, obj.width));

end


function frame = pon(height, width)
frame = 255 * ones(height, width, 'uint8');
end