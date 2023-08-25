function alp_returnvalue = seqcontrol(obj, deviceid, sequenceid, controltype, ...
    controlvalue)
%  Changes display properties of a sequence
%
%  See also:
%     seqinquire
%
%  File information:
%     version 1.0 (feb 2014)
%     (c) Martin Vogel
%     email: matlab@martin-vogel.info
%
%  Revision history:
%     1.0 (feb 2014) initial release version

if nargin < 5

    alp_returnvalue = obj.MISSING_PARAMETERS;
    obj.log('log', sprintf('Not enough parameters in call to AlpSeqControl(): %i given, %i needed.', ...
        nargin, 5));

else

    if obj.pseudoDLL
        alp_returnvalue = obj.OK;
    else
        if isempty(obj.libalias)
            alp_returnvalue = obj.LIBRARY_NOT_LOADED;
        else
            % call DLL function
            alp_returnvalue = calllib(obj.libalias, 'AlpSeqControl', ...
                deviceid, sequenceid, controltype, controlvalue);
        end
    end

    obj.log('log', sprintf(['[alp_returnvalue=%i] = AlpSeqControl(deviceid=%i, ', ...
        'sequenceid=%i, controltype=%i, controlvalue=%i)'], ...
        alp_returnvalue, deviceid, sequenceid, controltype, controlvalue));

end

end
