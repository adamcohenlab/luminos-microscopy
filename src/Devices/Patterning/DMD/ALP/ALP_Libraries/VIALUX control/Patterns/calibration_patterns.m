function [alp_pattern_data, bincode] = calibration_patterns(block_dimensions, projection_element, super_mask, offset)
%calibration_patterns   Generate dot patterns for calibration
%   [alp_pattern_data, bincode] = calibration_patterns(block_dimensions,...
%                                   projection_element,super_mask)
%
%   This function should be used as a drop-in replacement for
%   hadamard_patterns. It generates patterns with the same properties but
%   using a binary encoding identity matrix instead of a hadamard matrix,
%   resulting in a spinning disk confocal style of illumination. These
%   patterns are useful to calibrate and test a patterned illumination
%   projection system.
%
%   Input
%       block_dimensions: [block_rows, block_cols], or just one number
%       that means both.
%       projection_element: 'binning' of the pattern, projection element is
%       a multiplier for the pixel size in the pattern
%       super_mask: overall mask that will be applied to the pattern.
%       offset: [row_offset, col_offset], pixel offset for the patterns
%
%   Output
%       alp_pattern_data: 3D matrix with the desired patterns. number of
%       frames should be block_rows*block_cols rounded to the next multiple
%       of four. this matrix is in binary_top_down format.
%       bincode: a matrix that fully defines the pattern encoding that was
%       used.
%
%   [...] = hadamard_patterns(block_dimensions,projection_element) sets
%   a mask of all ones.
%   [...] = [...] = hadamard_patterns(block_dimensions) also sets
%   projection_element = 1
%
%   See also hadamard_patterns, hadamard_bincode, sim_patterns.
%
%   2016 Vicente Parot
%   Cohen Lab - Harvard University

[device_rows, device_cols, active_rows, active_cols, ...
    active_row_offset, active_col_offset] = pixel_configuration;

if nargin > 3
    active_row_offset = offset(1);
    active_col_offset = offset(2);
    active_rows = min(active_rows, device_rows-active_row_offset);
    active_cols = min(active_cols, device_cols-active_col_offset);
end
if nargin < 3
    super_mask = ones(device_rows, device_cols);
end
if nargin < 2
    projection_element = 1;
end
switch numel(block_dimensions)
    case 1
        block_rows = block_dimensions;
        block_cols = block_dimensions;
    case 2
        block_rows = block_dimensions(1);
        block_cols = block_dimensions(2);
    otherwise
        error 'check block_dimensions'
end

block_rows = max(round(block_rows), 2);
block_cols = max(round(block_cols), 2);
projection_element = max(round(projection_element), 1);

bincode = hadamard_bincode(block_rows*block_cols);

bincode = [ones(size(bincode, 1), 1), eye(size(bincode, 1)), zeros(size(bincode, 1), size(bincode, 2)-size(bincode, 1)-1)];
bitplanes = size(bincode, 2);
xspat = repmat( ...
    imresize(reshape(uint8(bincode), block_rows, block_cols, []), projection_element, 'nearest'), ...
    ceil([device_rows / block_rows, device_cols / block_cols]./projection_element));

bdepth = 8;
bitplane_upper_bound = ceil(bitplanes/bdepth) * bdepth;
xspat(:, :, bitplanes+1:bitplane_upper_bound) = 0;
bitplane_indices = 1:bitplane_upper_bound;
ibit = mod(bitplane_indices-1, 8); % 7-
p2 = permute(2.^ibit, [1, 3, 2]);
patpow = bsxfun(@times, uint8(xspat), uint8(p2));
alp_pattern_data = zeros(device_rows, device_cols, bitplane_upper_bound/bdepth, 'uint8');
for it = 1:bitplane_upper_bound / bdepth
    alp_pattern_data( ...
        (1:active_rows)+active_row_offset, ...
        (1:active_cols)+active_col_offset, it) = sum(patpow( ...
        (1:active_rows)+active_row_offset, ...
        (1:active_cols)+active_col_offset, (it - 1)*bdepth+(1:bdepth)), 3);
end
alp_pattern_data = bsxfun(@times, alp_pattern_data, uint8(super_mask));
alp_pattern_data = alp_msb_to_btd(alp_pattern_data);
alp_pattern_data = alp_pattern_data(:, :, 1:bitplanes);