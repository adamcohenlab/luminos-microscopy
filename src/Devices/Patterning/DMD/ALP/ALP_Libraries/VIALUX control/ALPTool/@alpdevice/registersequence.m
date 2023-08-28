function obj = registersequence(obj, sequence)
% register sequence with device

if ~isa(sequence, 'alpsequence')
    return;
end
% scan sequences array to avoid doubled entries
for si = 1:length(obj.sequences)
    if isequal(obj.sequences(si), sequence)
        return;
    end
end
obj.sequences(end+1) = sequence;
end
