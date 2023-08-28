function [alp_returnvalue, sequenceid] = alloc(obj, bitplanes, picnum)
%  Allocates memory for a new sequence of pictures
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

if nargin < 3

    alp_returnvalue = obj.MISSING_PARAMETERS;
    sequenceid = 0;

else

    if ~isempty(obj.device.deviceid)
        [alp_returnvalue, sequenceid] = ...
            obj.device.api.seqalloc(obj.device.deviceid, bitplanes, ...
            picnum);
        obj.sequenceid = sequenceid;
    else
        alp_returnvalue = obj.INVALID_ID;
        sequenceid = 0;
    end

end

end
