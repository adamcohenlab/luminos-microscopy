function h = libHadamard(n, testOnly)
%libHadamard constructs a Hadamard matrix.
%   libHadamard(N) returns a normalized Hadamard matrix of size N, or empty
%   matrix if the algorithm doesn't make that size of Hadamard matrix.
%   libHadamard(N,testOnly) returns true or false depending on whether the
%   algorithm makes that size of Hadamard matrix.
%
%   Some known hadamard matrices have been included in this library,
%   obtained from http://neilsloane.com/hadamard/ , made available by
%   N.J.A. Sloane.
%
%   See also hadamard.

%   2016 Vicente Parot
%   Cohen Lab - Harvard University

if ~exist('testOnly', 'var')
    testOnly = false;
end
factors = pickFactors(n);
if testOnly
    h = ~isempty(factors);
else
    hlib = [; ... % list of some stored hadamard matrices
        28, 36, 44, 52, 56, 60, 68, 72, 76, 84, 88, 92, 100, 104, 108, 112, 116, 120, ...
        124, 132, 136, 140, 144, 148, 152, 156, 164, 168, 172, 176, 180, 184, 188, ...
        196, 200, 204, 208, 212, 216, 220, 224, 228, 232, 236, 240, 244, 248, 252];
    %     hlib = [ % list of some stored hadamard matrices that Matlab doesn't make
    %         28 36 44 52 60 68 76 84 92 100 108 116 ...
    %         124  132  140  148 152 156 164 172 180 ...
    %         188  196  204  212 220 228 236 244 252];
    if ismember(n, hlib)
        [p, ~, ~] = fileparts(mfilename('fullpath'));
        dirlist = dir(fullfile(p, 'hadlib', ['had.', num2str(n), '.*']));
        assert(isequal(length(dirlist), 1), 'Hadamard library data confusing')
        h = 44 - cell2mat(strsplit(fileread(fullfile(p, 'hadlib', dirlist.name)), char(10))');
        h = bsxfun(@times, h, h(1, :));
        h = bsxfun(@times, h, h(:, 1));
    elseif ( ...
            (~mod(log2(n), 1) && log2(n) >= 0) || ...
            (~mod(log2(n/12), 1) && log2(n/12) >= 0) || ...
            (~mod(log2(n/20), 1)) && log2(n/20) >= 0)
        h = hadamard(n);
    elseif ~isempty(factors)
        h = 1;
        for it = 1:numel(factors)
            h = kron(h, libHadamard(factors(it)));
        end
    else
        h = [];
    end
end
