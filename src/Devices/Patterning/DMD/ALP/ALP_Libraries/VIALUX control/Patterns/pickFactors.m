function factors = pickFactors(product, possibleFactors)
%pickFactors Factorizes into dimensions of known Hadamard matrix sizes.
%   pickFactors(N) returns a factorization of the input product into
%   factors in the set of known hadamard matrix sizes [2 4:4:2^8]. If this
%   is not possible, returns an empty array. The algorithm is greedy: from
%   multiple options, it will select the one with largest factors.
%
%   Some known hadamard matrices have been included in this library,
%   obtained from http://neilsloane.com/hadamard/ , made available by
%   N.J.A. Sloane.
%
%   See also nextHadamard.

%   2016 Vicente Parot
%   Cohen Lab - Harvard University

if ~exist('possibleFactors', 'var')
    possibleFactors = [2, 4:4:2^8];
end
possibleFactors(possibleFactors == 1) = [];
divIdx = find(~rem(product, possibleFactors));
if isempty(divIdx)
    factors = [];
else
    for it = numel(divIdx):-1:1
        lowerFactors = pickFactors(product./possibleFactors(divIdx(it)), possibleFactors);
        factors = [lowerFactors, possibleFactors(divIdx(it))];
        if product == prod(factors)
            break
        else
            factors = [];
        end
    end
end
end