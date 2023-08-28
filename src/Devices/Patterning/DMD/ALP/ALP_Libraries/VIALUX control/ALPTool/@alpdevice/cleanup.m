function cleanup(obj)
obj.halt();
% delete left-over sequences
while ~isempty(obj.sequences)
    delete(obj.sequences(1));
end
end
