function alp_logical_patterns = alp_btd_to_logical(btd)

%%
% 2016 Vicente Parot
% Cohen Lab - Harvard University
%
[device_rows, device_cols] = pixel_configuration;
alp_logical_patterns = false(device_rows, device_cols, size(btd, 3));
for patidx = 1:size(alp_logical_patterns, 3);
    alp_logical_patterns(:, :, patidx) = ~ ~reshape(permute(cell2mat(arrayfun(@(n) ~ ~bitget(btd(:, :, patidx), n), permute(8:-1:1, [1, 4, 3, 2]), 'uni', false)), [4, 1, 2, 3]), device_rows, device_cols, []);
end
end
