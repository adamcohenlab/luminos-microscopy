function hash = hash_fcn(fhandle)
% hash_fcn provides serves as checksum for custom matlab functions codes.
% hash = hash_fcn(fhandle) returns a 128-bit universally unique identifier.
% See https://en.wikipedia.org/wiki/Universally_unique_identifier. fhandle
% must be a function handle to a function for which there is code available
% in a file; the function's code is hashed. For example,
% hash_fcn(@hash_fcn) returns something different, but in the same format
% of '915c0a73-fe90-3d0d-a1c4-88524fdd25b0'.
%
% 2016 Vicente Parot
% Cohen Lab - Harvard University
%
patfcn = functions(fhandle);
hash_data = {fileread(patfcn.file)};
charinds = cell2mat(cellfun(@ischar, hash_data, 'uniformoutput', false));
hash_data(charinds) = cellfun(@uint8, hash_data(charinds), 'uniformoutput', false);
uints = cell2mat(cellfun(@(el)typecast(reshape(el, 1, []), 'uint8'), hash_data, 'uniformoutput', false));
hash = char(java.util.UUID.nameUUIDFromBytes(uints)); % md5 hash - 128 bits
end
