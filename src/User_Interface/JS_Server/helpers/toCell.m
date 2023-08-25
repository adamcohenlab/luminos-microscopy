function out = toCell(x)
%TOCELL convert to cell if not already
if iscell(x)
    out = x;
elseif size(x, 2) > 1
    % turn into a cell array of cells
    % x is a (n, m1, m2, ...) array, and we want to turn it into a {n,1} cell array of {m1,m2,...} arrays
    out = cell(size(x, 1), 1);
    for i = 1:size(x, 1)
        out{i} = squeeze(x(i, :, :, :));
    end

else
    out = num2cell(x);
end
