function [alp_returnvalue, uservar] = projinquire(obj, deviceid, inquiretype)
%  Inquires system parameters of an ALP system
%
%  See also:
%     projcontrol
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
    uservar = 0;
    obj.log('log', sprintf('Not enough parameters in call to AlpProjInquire(): %i given, %i needed.', ...
        nargin, 3));

else

    if obj.pseudoDLL
        alp_returnvalue = obj.OK;
        uservar = 0;
    else
        if isempty(obj.libalias)
            alp_returnvalue = obj.LIBRARY_NOT_LOADED;
            uservar = 0;
        else
            % prepare pointer to long (int32) for 3rd parameter
            uservar = int32(0);
            uservarptr = libpointer('int32Ptr', uservar);
            % call DLL function
            [alp_returnvalue, uservar] = calllib(obj.libalias, 'AlpProjInquire', ...
                deviceid, inquiretype, uservarptr);
        end
    end

    obj.log('log', sprintf(['[alp_returnvalue=%i,uservar=%i] = ', ...
        'AlpProjInquire(deviceid=%i, inquiretypee=%i)'], ...
        alp_returnvalue, uservar, deviceid, inquiretype));

end

end
