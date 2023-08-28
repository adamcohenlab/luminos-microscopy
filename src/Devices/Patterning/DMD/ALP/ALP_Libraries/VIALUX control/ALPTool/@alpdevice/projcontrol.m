function alp_returnvalue = projcontrol(obj, controltype, controlvalue)
%  Changes system parameters of an ALP system
%
%  See also:
%     projinquire
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

    if ~isempty(obj.deviceid)
        alp_returnvalue = obj.api.projcontrol(obj.deviceid, ...
            controltype, controlvalue);
    else
        alp_returnvalue = obj.INVALID_ID;
    end

end

end
