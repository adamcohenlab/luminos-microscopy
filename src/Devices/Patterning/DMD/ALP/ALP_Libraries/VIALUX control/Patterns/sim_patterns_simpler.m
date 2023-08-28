function [alp_pattern_data, bincode] = sim_patterns(block_dimensions, p1, p2, p3, super_mask, reduced, usedither)
%sim_patterns   Generate Hadamard patterns.
%   [alp_pattern_data, bincode] = sim_patterns(block_dimensions,...
%                               p1,p2,p3,...
%                               super_mask,reduced,usedither)
%
%   Input
%       block_dimensions: [block_rows, block_cols], or just one number
%       that means both, or an empty matrix that also works when reduced is
%       false or omitted.
%       p1,p2,p3: period of the sim patterns along dimensions 1, 2, 3.
%       Setting the period to one will make the pattern constant along that
%       dimension, with all ones. One standard example could use 12, 1, 3
%       or 1, 12, 3.
%       super_mask: overall mask that will be applied to the pattern.
%       Accepts an empty matrix interpreted as all ones mask.
%       reduced, usedither: logical flags that default to false if omitted,
%       respectively for generating 1) only p3 frames instead of the
%       matching hadamard length, and 2) dithered version of the patterns
%       using the Floyd-Steinberg algorithm.
%
%   Output
%       alp_pattern_data: 3D matrix with the desired patterns. Number of
%       frames should be block_rows*block_cols rounded to the next multiple
%       of four for sequences mathing length of hadamard patterns, or p3
%       for reduced sequences. This matrix is in binary_top_down format.
%       bincode: The matrix that represents the hadamard patterns of the
%       corresponding matching length.
%
%   [...] = sim_patterns(block_dimensions,p1,p2,p3,super_mask,reduced)
%   defaults usedither to false.
%   [...] = sim_patterns(block_dimensions,p1,p2,p3,super_mask) also
%   defaults reduced to false.
%   [...] = sim_patterns(block_dimensions,p1,p2,p3) also defaults
%   super_mask to all ones.
%   [...] = sim_patterns(block_dimensions,p1,p2) also defaults to p3 = 3.
%   [...] = sim_patterns(block_dimensions,p1) also defaults to p2 = 1.
%   The block simensions are not needed for the pattern specification, but
%   will make the output matrix the same size as the hadamard patterns, for
%   comparison experiments that run for the same total time. The
%   block_dimensions parameter, however, is required. it can be set to []
%   if reduced patterns are to be requested.
%
%   See also hadamard_patterns, dither.
%
%   2016 Vicente Parot
%   Cohen Lab - Harvard University

switch numel(block_dimensions)
    case 0
        reduced = true;
        block_rows = 2;
        block_cols = 2;
    case 1
        block_rows = block_dimensions;
        block_cols = block_dimensions;
    case 2
        block_rows = block_dimensions(1);
        block_cols = block_dimensions(2);
    otherwise
        error 'check block_dimensions'
end
[device_rows, device_cols, active_rows, active_cols, ...
    active_row_offset, active_col_offset] = pixel_configuration;
if ~exist('super_mask', 'var') || isempty(super_mask), super_mask = true(device_rows, device_cols); end % by default, use all ones mask
if ~exist('reduced', 'var'), reduced = false; end % by default, generate enough patterns to match hadamard length of those block dimensions
if ~exist('usedither', 'var'), usedither = false; end % by default, do not use dithering
if ~exist('p3', 'var'), p3 = 3; end % set default frame period to 3
if ~exist('p2', 'var'), p2 = 1; end % set default column period to 1 (no modulation)
block_rows = max(round(block_rows), 2);
block_cols = max(round(block_cols), 2);
p1 = uint32(max(round(p1), 1));
p2 = uint32(max(round(p2), 1));
p3 = uint32(max(round(p3), 1));
bincode = hadamard_bincode(block_rows*block_cols);
if reduced
    out_bitplanes = p3;
else
    out_bitplanes = size(bincode, 2);
end
x1 = uint32(permute(1:device_rows, [2, 1, 3])-1);
x2 = uint32(permute(1:device_cols, [1, 2, 3])-1);
x3 = uint32(permute(1:p3, [1, 3, 2])-1);
if usedither
    xspat = zeros(device_rows, device_cols, size(bincode, 2));
    for it = 1:numel(x3)
        cfun = double(bsxfun(@plus, p2*p3*x1, bsxfun(@plus, p1*p3*x2, p1*p2*x3(it)))) * 2 * pi / double(p1) / double(p2) / double(p3);
        xspat(:, :, it) = dither(sin(cfun)/2+.5);
    end
else
    xspat = mod(bsxfun(@plus, p2*p3*x1, bsxfun(@plus, p1*p3*x2, p1*p2*x3)), p1*p2*p3) * 2 < (p1 * p2 * p3);
end
xspat = bsxfun(@and, xspat, super_mask);
alp_pattern_data = alp_logical_to_btd(permute(xspat, [2, 1, 3]));
%     xspat = repmat(xspat,[1 1 ceil(size(bincode,2)/size(xspat,3))]);
%     xspat = xspat(:,:,1:min(size(bincode,2),end));
%     bdepth = 8;
%     bitplane_upper_bound = ceil(size(bincode,2)/bdepth)*bdepth;
%     xspat(:,:,out_bitplanes+1:bitplane_upper_bound) = 0;
%     bitplane_indices = 1:bitplane_upper_bound;
%     ibit = uint8(mod(bitplane_indices-1,8)); % 7-
%     powof2 = permute(2.^ibit,[1 3 2]);
%     patpow = bsxfun(@times,uint8(xspat),powof2);
%     alp_pattern_data = zeros(device_rows,device_cols,bitplane_upper_bound/bdepth,'uint8');
%     for it = 1:bitplane_upper_bound/bdepth
%         alp_pattern_data(...
%             (1:active_rows)+active_row_offset,...
%             (1:active_cols)+active_col_offset,it) = sum(patpow(...
%             (1:active_rows)+active_row_offset,...
%             (1:active_cols)+active_col_offset,(it-1)*bdepth+(1:bdepth)),3);
%     end
%     alp_pattern_data = bsxfun(@times,alp_pattern_data,uint8(super_mask));
%     alp_pattern_data = alp_msb_to_btd(alp_pattern_data);
%     alp_pattern_data = alp_pattern_data(:,:,1:out_bitplanes);