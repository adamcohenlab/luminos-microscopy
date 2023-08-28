function alp_returnvalue = seqfree(obj, deviceid, sequenceid)
%  Deallocates a previously allocated sequence
%
%  See also:
%     seqalloc
%
%  File information:
%     version 1.0 (feb 2014)
%     (c) Martin Vogel
%     email: matlab@martin-vogel.info
%
%  Revision history:
%     1.0 (feb 2014) initial release version

if nargin < 3

    alp_returnvalue = obj.MISSING_PARAMETERS;
    obj.log('log', sprintf('Not enough parameters in call to AlpSeqFree(): %i given, %i needed.', ...
        nargin, 3));

else

    if obj.pseudoDLL
        alp_returnvalue = obj.OK;
    else
        if isempty(obj.libalias)
            alp_returnvalue = obj.LIBRARY_NOT_LOADED;
        else
            % call DLL function
            alp_returnvalue = calllib(obj.libalias, 'AlpSeqFree', ...
                deviceid, sequenceid);
        end
    end

    obj.log('log', sprintf('[alp_returnvalue=%i] = AlpSeqFree(deviceid=%i, sequenceid=%i)', ...
        alp_returnvalue, deviceid, sequenceid));
end

end
