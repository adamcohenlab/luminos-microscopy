function alp_returnvalue = startcont(obj, sequence)
%  Starts the continuous playback of a previously loaded sequence
%
%  See also:
%     projhalt, projstart, projcontrol, seqcontrol, devhalt
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

else

    if ~isempty(obj.deviceid) && ~isempty(sequence.sequenceid)
        alp_returnvalue = obj.api.projstartcont(obj.deviceid, sequence.sequenceid);
    else
        alp_returnvalue = obj.INVALID_ID;
    end

end

end
