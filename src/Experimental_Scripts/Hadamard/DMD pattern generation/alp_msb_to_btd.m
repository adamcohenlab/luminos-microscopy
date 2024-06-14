% Copyright 2016-2017 Vicente Parot
% 
% Permission is hereby granted, free of charge, to any person obtaining a
% copy of this software and associated documentation files (the
% "Software"), to deal in the Software without restriction, including
% without limitation the rights to use, copy, modify, merge, publish,
% distribute, sublicense, and/or sell copies of the Software, and to permit
% persons to whom the Software is furnished to do so, subject to the
% following conditions:      
% 
% The above copyright notice and this permission notice shall be included
% in all copies or substantial portions of the Software.    
% 
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
% OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
% MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
% NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
% DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
% OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
% USE OR OTHER DEALINGS IN THE SOFTWARE.      
%
function btd = alp_msb_to_btd(msb)
%%
% 2016 Vicente Parot
% Cohen Lab - Harvard University

    [device_rows, device_cols] = pixel_configuration;
    bit_depth = uint8(8);
    stride = device_rows/bit_depth;
    logical_btd = zeros([size(msb) double(bit_depth)],'uint8');
    for it = 1:bit_depth
        logical_btd(:,:,:,it) = bitget(msb,it);
    end
    logical_btd = reshape(permute(logical_btd,[1 2 4 3]),device_rows,device_cols,[]);
    logical_btd = reshape(logical_btd,bit_depth,stride,device_cols,[]);
    btd = reshape(sum(bsxfun(@times,logical_btd,2.^(bit_depth-1:-1:0)'),'native'),stride,device_cols,[]);
end
