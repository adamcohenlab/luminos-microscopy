% Scripts to test various format conversion between patterns
%
% 2016 Vicente Parot
% Cohen Lab - Harvard University

%%
msb = round(phantom(768*3)*255);
msb = permute(reshape(msb(150+(1:2048), :), 2048, 768, []), [2, 1, 3]);
msb = permute(reshape(msb, 768, 1024, []), [2, 1, 3]);
msb = msb(:, :, end:-1:1);
% msb = reshape(ans(1:1024*768*2),1024,768,2);

%%
% sum(arrayfun(@(n)bitget(51,n),1:8).*2.^[0:7])
device_rows = 1024;
device_cols = 768;
bit_depth = 8;
stride = device_rows / bit_depth;
% btd = bitget(msb(:,:,1),1); % bit 8 is msb
btd = cell2mat(arrayfun(@(n) ~ ~bitget(msb, n), permute(1:8, [1, 4, 3, 2]), 'uni', false));
% btd = reshape(permute(btd,[1 2 4 3]),device_rows,device_cols,[]);
% btd = reshape(btd,bit_depth,stride,device_cols,[]);
% btd = reshape(sum(bsxfun(@times,btd,2.^(0:bit_depth-1)')),stride,device_cols,[]);

%% view custom patterns
% variable "a" must be a 3D matrix with patterns in the workspace
b = cell2mat(arrayfun(@(n) ~ ~bitget(a(:, :, 42), n), permute(8:-1:1, [1, 4, 3, 2]), 'uni', false));
b = reshape(permute(b, [4, 1, 2, 3]), 1024, 768, []);
imshow(b', [])
