function alp_returnvalue = control(obj, controltype, controlvalue)
%  Changes display properties of a sequence
%
%  See also:
%     inquire
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

else

    if ~isempty(obj.sequenceid) && ~isempty(obj.device.deviceid)
        alp_returnvalue = obj.device.api.seqcontrol(obj.device.deviceid, ...
            obj.sequenceid, ...
            controltype, ...
            controlvalue);
    else
        alp_returnvalue = obj.INVALID_ID;
    end
end

end
