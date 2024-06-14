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
function bincode = hadamard_bincode_nopermutation(length)
%hadamard_bincode_nopermutation Generate a Hadamard binary encoding matrix. 
%   bincode = hadamard_bincode(length) generates a zeros and ones matrix.
% 
%   Output
%       bincode: A truncated normalized Hadamard matrix.  
%       For length > 3, this matrix has more columns than rows, the first
%       column is all ones. For length < 256, it has as many columns as the
%       next multiple of 4 after length. For length > 255, it has less than
%       about sqrt(length) excess columns. Its rows are orthogonal:
%       (bincode-.5)*(bincode-.5)' is an identity matrix. Also, its rows
%       have equal sum, and its columns have close to length/2 sum, except
%       for column one which has sum length. 
% 
%   See also hadamard_patterns.
% 
%   2016 Vicente Parot
%   Cohen Lab - Harvard University

    bincode = ~~(nextHadamard(length)/2+.5);
    bincode = bincode(end-length+1:end,:);
end
