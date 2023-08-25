function bincode = hadamard_bincode_nopermutation(length)
%hadamard_bincode   Generate a randomized Hadamard binary encoding matrix.
%   bincode = hadamard_bincode(length) generates a zeros and ones matrix.
%
%   Output
%       bincode: A truncated pseudo randomized normalized Hadamard matrix.
%       For length > 3, this matrix has more columns than rows, the first
%       column is all ones. For length < 256, it has as many columns as the
%       next multiple of 4 after length. For length > 255, it has as many
%       columns as the next power of 2 after length. Its rows are
%       orthogonal: (bincode-.5)*(bincode-.5)' is an identity matrix. Also,
%       its rows have equal sum, and its columns have close to length/2
%       sum, except for column one which has sum length.
%
%   See also hadamard_patterns, calibration_patterns, sim_patterns.
%
%   2016 Vicente Parot
%   Cohen Lab - Harvard University

bincode = ~ ~(nextHadamard(length) / 2 + .5);
bincode = bincode(end-length+1:end, :);
end
