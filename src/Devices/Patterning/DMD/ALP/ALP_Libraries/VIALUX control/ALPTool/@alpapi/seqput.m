function alp_returnvalue = seqput(obj, deviceid, sequenceid, picoffset, ...
    picload, userarray)
%  Loads user supplied frame data to an ALP device
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

if nargin < 6

    alp_returnvalue = obj.MISSING_PARAMETERS;
    obj.log('log', sprintf('Not enough parameters in call to AlpSeqPut(): %i given, %i needed.', ...
        nargin, 6));

else

    if obj.pseudoDLL
        alp_returnvalue = obj.OK;
    else
        if isempty(obj.libalias)
            alp_returnvalue = obj.LIBRARY_NOT_LOADED;
        else
            % prepare pointer to userarray (voidPtr)
            userarrayptr = libpointer('voidPtr', userarray);
            % call DLL function
            alp_returnvalue = calllib(obj.libalias, 'AlpSeqPut', ...
                deviceid, sequenceid, picoffset, picload, userarrayptr);
        end
    end

    obj.log('log', sprintf(['[alp_returnvalue=%i] = AlpSeqPut(deviceid=%i, sequenceid=%i, ', ...
        'picoffset=%i, picload=%i, userarrayptr=<voidPtr>)'], ...
        alp_returnvalue, deviceid, sequenceid, picoffset, picload));

end

end
