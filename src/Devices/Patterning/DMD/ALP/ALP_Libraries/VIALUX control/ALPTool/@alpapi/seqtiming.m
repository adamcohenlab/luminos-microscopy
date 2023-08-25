function alp_returnvalue = seqtiming(obj, deviceid, sequenceid, illuminatetime, ...
    picturetime, triggerdelay, triggerpulsewidth, vddelay)
%  Controls the timing properties of a sequence display
%
%  See also:
%     seqcontrol, seqinquire
%
%  File information:
%     version 1.0 (feb 2014)
%     (c) Martin Vogel
%     email: matlab@martin-vogel.info
%
%  Revision history:
%     1.0 (feb 2014) initial release version

if nargin < 8

    alp_returnvalue = obj.MISSING_PARAMETERS;
    obj.log('log', sprintf('Not enough parameters in call to AlpSeqTiming(): %i given, %i needed.', ...
        nargin, 8));

else

    if obj.pseudoDLL
        alp_returnvalue = obj.OK;
    else
        if isempty(obj.libalias)
            alp_returnvalue = obj.LIBRARY_NOT_LOADED;
        else
            % call DLL function
            alp_returnvalue = calllib(obj.libalias, 'AlpSeqTiming', ...
                deviceid, sequenceid, illuminatetime, ...
                picturetime, triggerdelay, triggerpulsewidth, ...
                vddelay);
        end
    end

    obj.log('log', sprintf(['[alp_returnvalue=%i] = AlpSeqTiming(deviceid=%i, sequenceid=%i, ', ...
        'illuminatetime=%i, picturetime=%i, triggerdelay=%i, ', ...
        'triggerpulsewidth=%i, vdddelay=%i)'], ...
        alp_returnvalue, deviceid, sequenceid, illuminatetime, ...
        picturetime, triggerdelay, triggerpulsewidth, vddelay));

end

end
