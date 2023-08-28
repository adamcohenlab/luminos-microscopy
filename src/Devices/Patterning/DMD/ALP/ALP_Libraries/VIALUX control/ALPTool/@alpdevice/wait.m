function alp_returnvalue = wait(obj)
%  Wait for playback completion
%
%  projwait is CURRENTLY NOT SUPPORTED, as ALP devices currently do not
%  support synchronous display.
%
%  See also:
%     stop, start, startcont, projcontrol
%
%  File information:
%     version 1.0 (feb 2014)
%     (c) Martin Vogel
%     email: matlab@martin-vogel.info
%
%  Revision history:
%     1.0 (feb 2014) initial release version

if ~isempty(obj.deviceid)
    alp_returnvalue = obj.api.projwait(obj.deviceid);
else
    alp_returnvalue = obj.INVALID_ID;
end

end
