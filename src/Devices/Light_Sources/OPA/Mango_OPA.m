classdef Mango_OPA < Device

    properties (Transient)
        dev
        main_shutter
    end
    properties
        wavelength;
    end
    properties (GetAccess = public, SetAccess = private, Transient)
        device_busy_status;
    end

    methods
        function obj = Mango_OPA(Initializer)
            obj@Device(Initializer);
            %IP address is dynamically allocated, so it is more stable to
            %use computer name, which is fixed.
            obj.dev = instrfind('Type', 'tcpip', 'RemoteHost', 'MANGO-S08149', 'RemotePort', 50, 'Tag', '');
            if isempty(obj.dev)
                obj.dev = tcpip('MANGO-S08149', 50);
            else
                fclose(obj.dev);
                obj.dev = obj.dev(1);
            end
            fopen(obj.dev);
        end

        function delete(obj)
            fclose(obj.dev);
        end

        function wlen = get.wavelength(obj)
            wlen = str2double(query(obj.dev, 'mango:set_main_out_wavelength?', '%s\r\n', '%s\n'));
        end

        function set.main_shutter(obj, val)
            obj.Set_Main_Shutter(val);
        end

        function set.wavelength(obj, val)
            obj.Set_Wavelength_Blocking(val);
        end

        function status = get.device_busy_status(obj)
            status = query(obj.dev, '*BUSY?', '%s\r\n', '%s\n');
        end

        function Set_Wavelength(obj, nm)
            fprintf(obj.dev, '%s\r\n', strcat('mango:set_main_out_wavelength=', num2str(nm)));
            %            obj.wavelength=query(obj.dev,'mango:set_main_out_wavelength?','%s\r\n' ,'%s\n');
        end

        function Set_Wavelength_Blocking(obj, nm)
            fprintf(obj.dev, '%s\r\n', strcat('mango:set_main_out_wavelength=', num2str(nm)));
            while (strcmp(obj.device_busy_status, '2'))
                pause(.1);
            end
        end

        function Set_Main_Shutter(obj, set_state)
            if set_state
                fprintf(obj.dev, '%s\r\n', 'mango:shutter_main=true');
            else
                fprintf(obj.dev, '%s\r\n', 'mango:shutter_main=false');
            end
        end

        function Set_OPA_Shutter(obj, set_state)
            if set_state
                fprintf(obj.dev, '%s\r\n', 'mango:shutter_opa=true');
            else
                fprintf(obj.dev, '%s\r\n', 'mango:shutter_opa=false');
            end
        end

        function Set_Pump_Shutter(obj, set_state)
            if set_state
                fprintf(obj.dev, '%s\r\n', 'mango:shutter_pump_shg=true');
            else
                fprintf(obj.dev, '%s\r\n', 'mango:shutter_pump_shg=false');
            end
        end

        function Set_Bypass_Shutter(obj, set_state)
            if set_state
                fprintf(obj.dev, '%s\r\n', 'mango:shutter_bypass=true');
            else
                fprintf(obj.dev, '%s\r\n', 'mango:shutter_bypass=false');
            end
        end

    end
end