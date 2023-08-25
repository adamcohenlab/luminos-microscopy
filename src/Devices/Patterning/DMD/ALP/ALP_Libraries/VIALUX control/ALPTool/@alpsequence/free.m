function alp_returnvalue = free(obj)
%  Deallocates a previously allocated sequence
%
%  See also:
%     alloc
%
%  File information:
%     version 1.0 (feb 2014)
%     (c) Martin Vogel
%     email: matlab@martin-vogel.info
%
%  Revision history:
%     1.0 (feb 2014) initial release version

if ~isempty(obj.sequenceid) && ~isempty(obj.device.deviceid)
    alp_returnvalue = obj.device.api.seqfree(obj.device.deviceid, ...
        obj.sequenceid);
    obj.sequenceid = [];

else

    alp_returnvalue = obj.INVALID_ID;

end

end
