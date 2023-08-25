function [alp_patterns] = custom_patterns

%%
% This function is just a testground to call other pattern generating
% functions. if you care about its content, backup its code! this function
% is meant to be temporary and its code changed.
%
% 2016 Vicente Parot
% Cohen Lab - Harvard University

%     redmask = imread('C:\Data\Vicente\2016-09-15_QP26_C2_hadamard\S2\FOV3_d48_b23b2_1x1\blue\0.png')';

%     s4r = sim_patterns(blsz, 4, 1,4,allmask);
%     s4c = sim_patterns(blsz, 1, 4,4,allmask);
%     alp_patterns = interleave_3rd_d(...
%         hadamard_patterns(blsz, 1,allmask),...
%         interleave_3rd_d(s4r(:,:,1:end/2),s4c(:,:,1:end/2)));
% nlocations_and_offset = [35 10]; % [n offset], 36 patterns
% nlocations_and_offset = [59 09];  % [n offset], 60 patterns

% v img
redmask = imread('C:\Data\Yoav\2018-06-21_IVQ48-S7\slice1\FOV12\red\0.png')';
bluemask = imread('C:\Data\Yoav\2018-06-21_IVQ48-S7\slice1\FOV12\blue\0.png')';
redmask = ones(size(redmask));
bluemask = ones(size(bluemask));
blsz = [19, 5];
pats = hadamard_patterns_scramble_nopermutation(blsz, [2, 3], redmask);
pats = alp_btd_to_logical(pats);
%     hadtraces = hadamard_bincode_nopermutation(20-1)'*2-1;
%     moviefixsc(vm(pats)*hadtraces)
npats = ~pats & any(pats, 3);
%     pats = pats|bluemask;
%     npats = npats|bluemask;
pats = alp_logical_to_btd(pats);
npats = alp_logical_to_btd(npats);
alp_patterns = interleave_3rd_d(pats, npats);

% ca img
%     bluemask = imread('R:\blue\2.png')';
%     bluemask = ones(size(bluemask));
%     blsz = [35 10];
%     pats = hadamard_patterns_scramble_nopermutation(blsz,2,bluemask);
%     pats = alp_btd_to_logical(pats);
% %     hadtraces = hadamard_bincode_nopermutation(20-1)'*2-1;
% %     moviefixsc(vm(pats)*hadtraces)
%     npats = ~pats&any(pats,3);
%     pats = alp_logical_to_btd(pats);
%     npats = alp_logical_to_btd(npats);
%     alp_patterns = interleave_3rd_d(pats,npats);

%     blsz = [59 09];
%     blsz = [19 4];
%     blsz = [35 10];
%     blsz = [23 5];
%     pats = hadamard_patterns_scramble_nopermutation(blsz,2,bluemask);
%     pats = alp_btd_to_logical(pats);
%     npats = ~pats&any(pats,3);
%     pats = alp_logical_to_btd(pats);
%     npats = alp_logical_to_btd(npats);
%     alp_patterns = interleave_3rd_d(pats,npats);
%     hadtraces = hadamard_bincode_nopermutation(blsz(1))'*2-1;
%     moviesc(vm(alp_btd_to_logical(alp_patterns))*hadtraces)
%     zoom(5)


%     bm = hadamard_patterns([3 3], 1,bluemask);
%     bm = bm(:,:,1);
%     alp_patterns = bsxfun(@plus,alp_patterns,uint8(255*bm));

%     rm = hadamard_patterns([3 3], 1,redmask);
%     rm  = rm(:,:,1);
%     alp_patterns = bsxfun(@plus,alp_patterns,uint8(255*rm));
end

function inter = interleave_3rd_d(varargin)
%   interleaves series of patterns of equal length, for concurrent
%   acquisition.
inter = reshape(permute(cell2mat(permute(varargin, [1, 4, 3, 2])), [1, 2, 4, 3]), ...
    size(varargin{1}, 1), size(varargin{1}, 2), []);
end

function never_call_me_just_execute_the_script_blocks_to_test_patterns

%%
tic
a = custom_patterns;

toc

%% view custom patterns
patidx = 77 + 2 * 0;
b = cell2mat(arrayfun(@(n) ~ ~bitget(a(:, :, patidx), n), permute(8:-1:1, [1, 4, 3, 2]), 'uni', false));
b = reshape(permute(b, [4, 1, 2, 3]), 1024, 768, []);
imshow(b', [])

%%
%     patidx = 3000;
%     imshow(xspat(:,:,patidx),[])
end
