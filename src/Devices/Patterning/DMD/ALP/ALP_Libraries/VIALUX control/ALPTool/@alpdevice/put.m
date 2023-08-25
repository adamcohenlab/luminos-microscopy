function put(obj, frame)
%  Sets pixel to given frame
%
%  See also:
%
%
%  File information:
%     version 1.0 (feb 2014)
%     (c) Martin Vogel
%     email: matlab@martin-vogel.info
%
%  Revision history:
%     1.0 (feb 2014) initial release version

if ~isempty(obj.deviceid) && ~isempty(obj.sequences(1).sequenceid)

    % stop current playback
    obj.stop();
    obj.halt();

    % load frame to first sequence
    obj.sequences(1).put(0, 1, frame);

    % start sequence
    obj.startcont(obj.sequences(1));

end

end
