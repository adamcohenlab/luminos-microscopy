function [alp_returnvalue, uservar] = inquire(obj, inquiretype)
%  Inquires properties of an ALP system
%
%  See also:
%     devcontrol
%
%  File information:
%     version 1.0 (feb 2014)
%     (c) Martin Vogel
%     email: matlab@martin-vogel.info
%
%  Revision history:
%     1.0 (feb 2014) initial release version

if nargin < 2

    alp_returnvalue = obj.MISSING_PARAMETERS;
    uservar = 0;

else

    if ~isempty(obj.deviceid)
        [alp_returnvalue, uservar] = obj.api.devinquire(obj.deviceid, ...
            inquiretype);
    else
        alp_returnvalue = obj.INVALID_ID;
        uservar = 0;
    end

end

end
