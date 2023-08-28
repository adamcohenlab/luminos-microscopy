function sequence = stripes(obj, stripecount)
%  Sets all pixels to maximum value in stripes
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
    sequence = stripesframe(obj.height, obj.width, stripecount);
    return;
end

obj.put(stripesframe(obj.height, obj.width, stripecount));

end


function frame = stripesframe(height, width, stripescount)
frame = zeros(height, width, 'uint8');

for stripe = 1:stripescount
    if isodd(stripe)
        startrow = floor((height / stripescount)*(stripe - 1)+1);
        endrow = floor((height / stripescount)*stripe);
        frame(startrow:endrow, :) = uint8(255);
    end
end

end

function isodd = isodd(number)
if number / 2 == floor(number/2)
    isodd = false;
else
    isodd = true;
end
end
