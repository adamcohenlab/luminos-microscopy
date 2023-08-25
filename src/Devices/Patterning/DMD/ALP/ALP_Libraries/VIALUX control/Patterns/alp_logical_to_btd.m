function btd = alp_logical_to_btd(bin)

%%
% 2016 Vicente Parot
% Cohen Lab - Harvard University

[device_rows, device_cols] = pixel_configuration;
bit_depth = uint8(8);
stride = device_rows / bit_depth;
logical_btd = reshape(permute(uint8(bin), [1, 2, 3]), bit_depth, stride, device_cols, []);
btd = reshape(sum(bsxfun(@times, logical_btd, 2.^(bit_depth - 1:-1:0)'), 'native'), stride, device_cols, []);
end
