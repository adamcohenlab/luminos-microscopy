function [alp_returnvalue, sequenceid] = seqalloc(obj, deviceid, bitplanes, picnum)
%  Allocates memory for a new sequence of pictures
%
%  See also:
%     seqfree
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
    sequenceid = 0;
    obj.log('log', sprintf('Not enough parameters in call to AlpSeqAlloc(): %i given, %i needed.', ...
        nargin, 4));

else

    if obj.pseudoDLL
        alp_returnvalue = obj.OK;
        sequenceid = 0;
    else
        if isempty(obj.libalias)
            alp_returnvalue = obj.LIBRARY_NOT_LOADED;
            sequenceid = 0;
        else
            % prepare pointer to ALP_ID (uint32) for 4th parameter
            sequenceid = uint32(0);
            sequenceidptr = libpointer('uint32Ptr', sequenceid);
            % call DLL function
            [alp_returnvalue, sequenceid] = calllib(obj.libalias, 'AlpSeqAlloc', ...
                deviceid, bitplanes, picnum, sequenceidptr);
        end
    end

    obj.log('log', sprintf(['[alp_returnvalue=%i,sequenceid=%i] = AlpSeqAlloc(deviceid=%i, ', ...
        'bitplanes=%i, picnum=%i)'], alp_returnvalue, sequenceid, ...
        deviceid, bitplanes, picnum));

end

end
