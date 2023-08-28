function alp_returnvalue = stop(obj)
%  Stops the playback of the active sequence
%
%  See also:
%     start, startcont, projcontrol
%
%  File information:
%     version 1.0 (feb 2014)
%     (c) Martin Vogel
%     email: matlab@martin-vogel.info
%
%  Revision history:
%     1.0 (feb 2014) initial release version

if nargin < 1

    alp_returnvalue = obj.MISSING_PARAMETERS;

else

    if ~isempty(obj.deviceid)
        alp_returnvalue = obj.api.projhalt(obj.deviceid);
    else
        alp_returnvalue = obj.INVALID_ID;
    end

end

end
