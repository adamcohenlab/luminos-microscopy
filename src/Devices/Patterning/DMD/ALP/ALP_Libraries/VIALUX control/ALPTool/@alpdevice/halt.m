function alp_returnvalue = halt(obj)
%  Puts an ALP device in an idle wait state
%
%  See also:
%     start free
%
%  File information:
%     version 1.0 (feb 2014)
%     (c) Martin Vogel
%     email: matlab@martin-vogel.info
%
%  Revision history:
%     1.0 (feb 2014) initial release version

if ~isempty(obj.deviceid)
    % obj.api.projhalt(obj.deviceid);
    alp_returnvalue = obj.api.devhalt(obj.deviceid);
else
    alp_returnvalue = obj.INVALID_ID;
end

end
