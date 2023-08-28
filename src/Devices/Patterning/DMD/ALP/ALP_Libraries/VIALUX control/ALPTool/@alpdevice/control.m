function alp_returnvalue = control(obj, controltype, controlvalue)
%  Changes display properties of an ALP system
%
%  See also:
%     inquire
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

else

    if ~isempty(obj.deviceid)

        alp_returnvalue = obj.api.devcontrol(obj.deviceid, ...
            controltype, controlvalue);

        % handle specific case with "DEV_DMDTYPE" command
        if (controltype == obj.api.DEV_DMDTYPE) && ...
                (alp_returnvalue == obj.api.OK)
            switch controlvalue
                case obj.api.DMDTYPE_XGA % 1024*768 mirror pixels
                    obj.height = 1024;
                    obj.width = 768;

                case obj.api.DMDTYPE_SXGA_PLUS % 1400*1050 mirror pixels
                    obj.height = 1400;
                    obj.width = 1050;

                case obj.api.DMDTYPE_1080P_095A; % 1920*1080 mirror pixels (0.95" Type A, D4x00)
                    obj.height = 1920;
                    obj.width = 1080;

                case obj.api.DMDTYPE_XGA_07A % 1024*768 mirror pixels (0.7" Type A, D4x00)
                    obj.height = 1024;
                    obj.width = 768;

                case obj.api.DMDTYPE_XGA_055A % 1024*768 mirror pixels (0.55" Type A, D4x00)
                    obj.height = 1024;
                    obj.width = 768;

                case obj.api.DMDTYPE_XGA_055X % 1024*768 mirror pixels (0.55" Type X, D4x00)
                    obj.height = 1024;
                    obj.width = 768;

                case obj.api.DMDTYPE_DISCONNECT % behaves like 1080p (D4100)
                    obj.height = 1920;
                    obj.width = 1080;

                otherwise
                    obj.height = 1024;
                    obj.width = 768;

            end
        end

    else

        alp_returnvalue = obj.INVALID_ID;

    end

end

end
