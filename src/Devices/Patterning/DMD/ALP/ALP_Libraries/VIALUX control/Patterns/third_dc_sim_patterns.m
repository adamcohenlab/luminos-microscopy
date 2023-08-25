function [alp_pattern_data] = third_dc_sim_patterns(p1, p2, p3)

%%
% 2016 Vicente Parot
% Cohen Lab - Harvard University

if ~exist('p3', 'var'), p3 = 3; end % set default frame period to 3
if ~exist('p2', 'var'), p2 = 1; end % set default column period to 1 (no modulation)
[device_rows, device_cols, active_rows, active_cols, ...
    active_row_offset, active_col_offset] = pixel_configuration;
p1 = round(p1);
p2 = round(p2);
p3 = round(p3);
bitplanes = p3;
x1 = permute(1:device_rows, [2, 1, 3]) - 1;
x2 = permute(1:device_cols, [1, 2, 3]) - 1;
x3 = permute(1:p3, [1, 3, 2]) - 1;
xspat = mod(bsxfun(@plus, p2*p3*x1, bsxfun(@plus, p1*p3*x2, p1*p2*x3)), p1*p2*p3) * 3 < (p1 * p2 * p3);
% for it = 1:numel(x3)
%     xspat(:,:,it) = dither(sin(bsxfun(@plus,p2*p3*x1,bsxfun(@plus,p1*p3*x2,p1*p2*x3(it)))*2*pi/p1/p2/p3)/2+.5);
% end

bdepth = 8;
bitplane_upper_bound = ceil(bitplanes/bdepth) * bdepth;
xspat(:, :, bitplanes+1:bitplane_upper_bound) = 0;
bitplane_indices = 1:bitplane_upper_bound;
ibit = mod(bitplane_indices-1, 8); % 7-
p2 = permute(2.^ibit, [1, 3, 2]);
patpow = bsxfun(@times, xspat, p2);
alp_pattern_data = zeros(device_rows, device_cols, bitplane_upper_bound/bdepth, 'uint8');
for it = 1:bitplane_upper_bound / bdepth
    alp_pattern_data( ...
        (1:active_rows)+active_row_offset, ...
        (1:active_cols)+active_col_offset, it) = sum(patpow( ...
        (1:active_rows)+active_row_offset, ...
        (1:active_cols)+active_col_offset, (it - 1)*bdepth+(1:bdepth)), 3);
end
alp_pattern_data = alp_msb_to_btd(alp_pattern_data);
alp_pattern_data = alp_pattern_data(:, :, 1:bitplanes);