function packed = rle_encode(unpacked)
% rle_encode calculates the run length encoding of a data matrix
%   Disregards the dimension of the input matrix, so you must know it to
%   make sense of the data after decoding. rle_encode returns a sequence of
%   numbers of uint32 class that come in pairs, counting the number of
%   positions before the data changes from 0 to 1 or vice versa.
%   Fortunately, to decode: just use the function rle_decode. Limitation:
%   the first element in the data must be a zero.
%
% Example
%   % rbpats is a logical matrix of size [768 1024 17]
%   packed = rle_encode(rbpats);
%   fid = fopen('c:\vicente\custom_sequence.pat','w');
%   fwrite(fid,packed,'uint32');
%   fclose(fid);
%   % ---
%   fid = fopen('c:\vicente\custom_sequence.pat','r');
%   data = fread(fid,'*uint32');
%   fclose(fid);
%   rbread = reshape(rle_decode(data),[768,1024]);
%   % isequal(rbpats,rbread) returns 1
%
% 2016 Vicente Parot
% Cohen Lab - Harvard University
%
packed = uint32(diff(find(diff([-Inf; unpacked(:); Inf]))));
end