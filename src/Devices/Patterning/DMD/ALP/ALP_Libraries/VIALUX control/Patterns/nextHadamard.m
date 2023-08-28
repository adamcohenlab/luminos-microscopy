function h = nextHadamard(n)
%nextHadamard Returns a Hadamard matrix.
%   nextHadamard(N) gives a smallest Hadamard matrix with at least N+1 rows
%   in normalized form. For N up to 2^8, there are at most N+4 rows. For N
%   higher than 2^8, excess rows appear to be bounded by sqrt(N).
%
%   Some known hadamard matrices have been included in this library,
%   obtained from http://neilsloane.com/hadamard/ , made available by
%   N.J.A. Sloane.
%
%   See also hadamard.

%   2016 Vicente Parot
%   Cohen Lab - Harvard University

if n < 2
    h = hadamard(n+1);
else
    h = [];
    n = floor(n/4) * 4;
    while isempty(h)
        n = n + 4;
        h = libHadamard(n);
    end
end