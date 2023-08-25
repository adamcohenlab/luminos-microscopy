function btd = alp_msb_to_btd(msb)

%%
% 2016 Vicente Parot
% Cohen Lab - Harvard University

[device_rows, device_cols] = pixel_configuration;
bit_depth = uint8(8);
stride = device_rows / bit_depth;
[r, c, f] = size(msb);
logical_btd = zeros([[r, c, f], double(bit_depth)], 'uint8');
for it = 1:bit_depth
    logical_btd(:, :, :, it) = bitget(msb, it);
end
logical_btd = reshape(permute(logical_btd, [1, 2, 4, 3]), device_rows, device_cols, []);
logical_btd = reshape(logical_btd, bit_depth, stride, device_cols, []);
btd = reshape(sum(bsxfun(@times, logical_btd, 2.^(bit_depth - 1:-1:0)'), 'native'), stride, device_cols, []);
end
