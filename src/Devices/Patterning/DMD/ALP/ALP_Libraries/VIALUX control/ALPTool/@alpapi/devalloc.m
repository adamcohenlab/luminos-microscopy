function [alp_returnvalue, deviceid] = devalloc(obj, devicenumber, initflag)
%  Allocates an ALP hardware system (board set)
%
%  See also:
%     devfree
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
    obj.log('log', sprintf('Not enough parameters in call to AlpDevAlloc(): %i given, %i needed.', ...
        nargin, 3));

else

    if obj.pseudoDLL
        alp_returnvalue = obj.OK;
        deviceid = 0;
    else
        if isempty(obj.libalias)
            alp_returnvalue = obj.LIBRARY_NOT_LOADED;
            deviceid = obj.DEFAULT;
        else
            % prepare pointer to ALP_ID (uint32) for 3rd parameter
            deviceid = uint32(0);
            deviceidptr = libpointer('uint32Ptr', deviceid);
            % call DLL function
            [alp_returnvalue, deviceid] = calllib(obj.libalias, 'AlpDevAlloc', ...
                devicenumber, initflag, deviceidptr);
        end
    end

    obj.log('log', sprintf(['[alp_returnvalue=%i, deviceid=%i] = ', ...
        'AlpDevAlloc(devicenumber=%i, initflags=%i)'], ...
        alp_returnvalue, deviceid, devicenumber, initflag));

end

end
