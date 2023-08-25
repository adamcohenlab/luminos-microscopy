function [alp_returnvalue, uservar] = seqinquire(obj, deviceid, sequenceid, ...
    inquiretype)
%  Inquires display properties of a sequence
%
%  See also:
%     seqcontrol
%
%  File information:
%     version 1.0 (feb 2014)
%     (c) Martin Vogel
%     email: matlab@martin-vogel.info
%
%  Revision history:
%     1.0 (feb 2014) initial release version

if nargin < 4

    alp_returnvalue = obj.MISSING_PARAMETERS;
    uservar = 0;
    obj.log('log', sprintf('Not enough parameters in call to AlpSeqInquire(): %i given, %i needed.', ...
        nargin, 4));

else

    if obj.pseudoDLL
        alp_returnvalue = obj.OK;
        uservar = 0;
    else
        if isempty(obj.libalias)
            alp_returnvalue = obj.LIBRARY_NOT_LOADED;
            uservar = 0;
        else
            % prepare pointer to long (int32) for 4th parameter
            uservar = int32(0);
            uservarptr = libpointer('int32Ptr', uservar);
            % call DLL function
            [alp_returnvalue, uservar] = calllib(obj.libalias, 'AlpSeqInquire', ...
                deviceid, sequenceid, inquiretype, uservarptr);
        end
    end

    obj.log('log', sprintf(['[alp_returnvalue=%i, uservar=%i] = ', ...
        'AlpSeqInquire(deviceid=%i, sequenceid=%i, inquiretype=%i)'], ...
        alp_returnvalue, uservar, deviceid, sequenceid, inquiretype));

end

end
