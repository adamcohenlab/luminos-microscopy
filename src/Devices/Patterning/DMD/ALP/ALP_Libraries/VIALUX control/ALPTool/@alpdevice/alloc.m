function [alp_returnvalue, deviceid] = alloc(obj, devicenumber, initflag)
%  Allocates an ALP hardware system (board set)
%
%  See also:
%     free
%
%  File information:
%     version 1.0 (feb 2014)
%     (c) Martin Vogel
%     email: matlab@martin-vogel.info
%
%  Revision history:
%     1.0 (feb 2014) initial release version

% if there is already a board, release that!
if ~isempty(obj.deviceid)
    obj.cleanup();
    obj.free();
    obj.deviceid = [];
end

if nargin < 3
    initflag = obj.api.DEFAULT;
end
if nargin < 2
    devicenumber = obj.api.DEFAULT;
end

[alp_returnvalue, deviceid] = obj.api.devalloc(devicenumber, initflag);

if alp_returnvalue == obj.api.OK
    obj.deviceid = deviceid;
end

% allocate one sequence with one frame for still images
seq = alpsequence(obj);
seq.alloc(1, 1);
obj.sequences = seq;

end
