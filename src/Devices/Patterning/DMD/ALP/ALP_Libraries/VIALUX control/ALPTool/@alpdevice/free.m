function alp_returnvalue = free(obj)
%  Deallocates a previously allocated ALP device
%
%  See also:
%     alloc, halt
%
%  File information:
%     version 1.0 (feb 2014)
%     (c) Martin Vogel
%     email: matlab@martin-vogel.info
%
%  Revision history:
%     1.0 (feb 2014) initial release version

if ~isempty(obj.deviceid)

    % halt device and remove all sequences
    obj.cleanup();
    % unlink device from driver
    alp_returnvalue = obj.api.devfree(obj.deviceid);
    obj.deviceid = [];

else

    alp_returnvalue = obj.INVALID_ID;

end

end
