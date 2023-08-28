function [alp_pattern_data, bincode] = hadamard_patterns_scramble(nblock_and_step, projection_element, super_mask)
%hadamard_patterns   Generate Hadamard patterns.
%   [alp_pattern_data, bincode] = hadamard_patterns(block_dimensions,...
%                                   projection_element,super_mask)
%
%   Input
%       block_dimensions: [block_rows, block_cols], or just one number
%       that means both.
%       projection_element: 'binning' of the pattern, projection element is
%       a multiplier for the pixel size in the pattern
%       super_mask: overall mask that will be applied to the pattern.
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
%   See also calibration_patterns, sim_patterns, hadamard_bincode.
%
%   2016 Vicente Parot
%   Cohen Lab - Harvard University

[device_rows, device_cols, active_rows, active_cols, ...
    active_row_offset, active_col_offset] = pixel_configuration;

if nargin < 3
    super_mask = ones(device_rows, device_cols);
end
if nargin < 2
    projection_element = 1;
end
%     switch numel(block_dimensions)
%         case 1
%             block_rows = block_dimensions;
%             block_cols = block_dimensions;
%         case 2
%             block_rows = block_dimensions(1);
%             block_cols = block_dimensions(2);
%         otherwise
%             error 'check block_dimensions'
%     end

%     block_rows = max(round(block_rows),2);
%     block_cols = max(round(block_cols),2);
projection_element = max(round(projection_element), 1);

%     bincode = hadamard_bincode(block_rows*block_cols);
%     assert(block_rows == 3 && block_cols == 3,'only works for 12 patterns in 11 locations')

nblock = nblock_and_step(1);
blockstep = nblock_and_step(2);
bincode = hadamard_bincode(nblock);
bitplanes = size(bincode, 2);
plind = mod(bsxfun(@plus, blockstep*(0:nblock - 1)', 0:nblock-1), nblock) + 1;
[rr, cc] = find(plind);
xs = false(nblock*[1, 1, 1]);
xs(sub2ind(nblock*[1, 1, 1], rr, cc, plind(:))) = true;
xs = reshape(xs, [nblock * nblock, nblock]);
xs = ~ ~(double(xs) * double(bincode));
xs = reshape(xs, [nblock, nblock, bitplanes]);

%     xs = bsxfun(@times,xs*2-1,((mod((1:nblock)-1,blockstep)>=ceil(blockstep/2))*2-1))/2+.5;
%     xs = bsxfun(@times,xs*2-1,(mod(1:nblock,blockstep*2)>=blockstep)*2-1)/2+.5;
xs = bsxfun(@times, xs*2-1, mod(1:nblock, 2)'*2-1) / 2 + .5; % works fine with 11,3; 63,14; 19,5;
xs = ~[xs; ~xs];
%     xs = ~[xs ~xs];

xspat = repmat( ...
    imresize(xs, projection_element, 'nearest'), ...
    ceil([device_rows / nblock / 2, device_cols / nblock]./projection_element));

xsrand = sign(randn(nblock*[2, 1].*ceil([device_rows / nblock / 2, device_cols / nblock]./projection_element)));
xsfullrand = imresize(xsrand, projection_element, 'nearest');

xspat = bsxfun(@xor, xspat, xsfullrand > 0);

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