function alp_returnvalue = timing(obj, illuminatetime, picturetime, triggerdelay, triggerpulsewidth, vddelay)
%  Controls the timing properties of a sequence display
%
%  See also:
%     control, inquire
%
%  File information:
%     version 1.0 (feb 2014)
%     (c) Martin Vogel
%     email: matlab@martin-vogel.info
%
%  Revision history:
%     1.0 (feb 2014) initial release version

if nargin < 6

    alp_returnvalue = obj.MISSING_PARAMETERS;

else

    if ~isempty(obj.sequenceid) && ~isempty(obj.device.deviceid)
        alp_returnvalue = obj.device.api.seqtiming(obj.device.deviceid, ...
            obj.sequenceid, ...
            illuminatetime, ...
            picturetime, ...
            triggerdelay, ...
            triggerpulsewidth, ...
            vddelay);
    else
        alp_returnvalue = obj.INVALID_ID;
    end

end

end
