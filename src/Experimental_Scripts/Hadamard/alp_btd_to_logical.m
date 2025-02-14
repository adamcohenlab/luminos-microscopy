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
function alp_logical_patterns = alp_btd_to_logical(btd)
%%
% 2016 Vicente Parot
% Cohen Lab - Harvard University
% 
    [device_rows, device_cols] = pixel_configuration;
    alp_logical_patterns = false(device_rows,device_cols,size(btd,3));
    for patidx = 1:size(alp_logical_patterns,3);
        alp_logical_patterns(:,:,patidx) = ~~reshape(permute(cell2mat(arrayfun(@(n)~~bitget(btd(:,:,patidx),n),permute(8:-1:1,[1 4 3 2]),'uni',false)),[4 1 2 3]),device_rows,device_cols,[]);
    end
end
