function obj = unregistersequence(obj, sequence)
% unregister sequence from device
if ~isa(sequence, 'alpsequence')
    return;
end
% scan sequences array to avoid doubled entries
for si = 1:length(obj.sequences)
    if isequal(obj.sequences(si), sequence)
        obj.sequences(si) = [];
        return;
    end
end
end
