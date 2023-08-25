classdef Cobolt_Laser < Laser_Device
    properties (Transient)
        SPORT %serial communication
        COMPORT
        HANDSHAKE = true; %Whether or not the device will return a handshake line ("OK") after successful command
        %If HANDSHAKE is true, then the client needs to wait for the
        %handshake before trying to send another command. This can be done
        %by calling readline() on the expected handshake, ignoring the
        %result.
    end
    properties
        Mode;
    end

    methods
        function obj = Cobolt_Laser(Initializer)
            obj@Laser_Device(Initializer);
            obj.COMPORT = obj.Initializer.COMPORT;
            obj.SPORT = serialport(obj.COMPORT, 115200, 'Timeout', obj.port_timeout); %Matlab defaults to appropriate Parity etc.
            configureTerminator(obj.SPORT, "CR"); %Set the terminator to carriage return
            obj.Mode = 'CWP';
            obj.Wavelength = Initializer.Wavelength;
            obj.initialize_props();
            obj.Set_Autostart(false); %Turn off autostart mode to allow for manual control.
            obj.Set_keyEnabled(false); %Override keyswitch
            obj.Clear_Faults();
            obj.Stop();
        end

        function Start(obj)
            writeline(obj.SPORT, 'l1');
            if obj.HANDSHAKE
                readline(obj.SPORT);
            end
        end

        function Stop(obj)
            writeline(obj.SPORT, 'l0');
            if obj.HANDSHAKE
                readline(obj.SPORT);
            end
        end

        function state = Get_state(obj)
            flush(obj.SPORT);
            writeline(obj.SPORT, 'l?');
            state = strip(readline(obj.SPORT));
            state = strcmp(state, '1');
            %             if obj.HANDSHAKE
            %                 readline(obj.SPORT);
            %             end
        end
        function wavelength = Get_wav(obj)
            wavelength = obj.Initializer.Wavelength;
        end
        function power_rating = Get_powRating(obj)
            power_rating = obj.Initializer.maxPower;
        end
        function limits = Get_powLimits(obj)
            limits = [obj.Initializer.maxPower * 0.1, obj.Initializer.maxPower * 1];
        end
        %return current head output power in Watts
        function power = Get_pow(obj)
            flush(obj.SPORT);
            writeline(obj.SPORT, "pa?");
            power = str2double(readline(obj.SPORT));
            %             if obj.HANDSHAKE
            %                 readline(obj.SPORT);
            %             end
        end

        %return current output power setting in Watts (may not be the
        %actual power output, and will return the setting even if laser is off).
        function power = Get_pow_set(obj)
            flush(obj.SPORT);
            writeline(obj.SPORT, "p?");
            power = str2double(readline(obj.SPORT));
            %             if obj.HANDSHAKE
            %                 readline(obj.SPORT);
            %             end
        end

        %Set laser output power setting in Watts. Does not turn laser on.
        function Set_pow(obj, pow)
            writeline(obj.SPORT, ['p ', num2str(pow)])
            if obj.HANDSHAKE
                readline(obj.SPORT);
            end
        end

        %return boolean specifying whether laser is enabled by
        %interlock. true = laser enabled. false = interlock off.
        function enabled = Get_interlockStatus(obj)
            flush(obj.SPORT);
            writeline(obj.SPORT, "ilk?");
            enabled = strcmp(strip(readline(obj.SPORT)), "0");
            %             if obj.HANDSHAKE
            %                 readline(obj.SPORT);
            %             end
        end
        %return boolean specifying whether laser is enabled by
        %keyswitch. true = laser enabled. false = keyswitch off.
        function enabled = Get_keyStatus(obj)
            flush(obj.SPORT);
            writeline(obj.SPORT, "@cobasky?");
            enabled = strcmp(strip(readline(obj.SPORT)), "1");
            %             if obj.HANDSHAKE
            %                 readline(obj.SPORT);
            %             end
        end

        %enable or disable keyswitch control. If disabled, laser can emit
        %regardless of keyswitch state.
        function Set_keyEnabled(obj, tf)
            writeline(obj.SPORT, ['@cobasky ', num2str(logical(tf))])
            if obj.HANDSHAKE
                readline(obj.SPORT);
            end
        end

        %Enable or disable autostart mode. If autostart enabled, laser will
        %automatically emit when powered and key switch on (if key control
        %enabled). Manual 'Start' command will not work. If disabled, laser
        %is in manual control mode, with emission controlled by start and
        %stop.
        function Set_Autostart(obj, tf)
            writeline(obj.SPORT, ['@cobas ', num2str(logical(tf))])
            if obj.HANDSHAKE
                readline(obj.SPORT);
            end
        end

        %Check whether laser is in autostart mode
        function enabled = Get_Autostart(obj)
            flush(obj.SPORT);
            writeline(obj.SPORT, "@cobas?");
            enabled = strcmp(strip(readline(obj.SPORT)), "1");
            %             if obj.HANDSHAKE
            %                 readline(obj.SPORT);
            %             end
        end

        %If interlock is opened, or other fault occurs, faults need to be
        %cleared before restarting.
        function Clear_Faults(obj)
            writeline(obj.SPORT, "cf");
            if obj.HANDSHAKE
                readline(obj.SPORT);
            end
            writeline(obj.SPORT, "@cob1");
            if obj.HANDSHAKE
                readline(obj.SPORT);
            end
        end

        function faultcode = Check_Faults(obj)
            flush(obj.SPORT);
            writeline(obj.SPORT, "f?");
            faultcode = str2double(strip(readline(obj.SPORT)));
        end

        %This method allows the client to get a list of the available modes
        function modes = Get_available_modes(obj)
            modes = ["CWP", "DIG"];
        end

        %sets operating mode of laser: CWP = constant power; CWC =
        %constant current; DIG = external digital modulation; ANAL =
        %external analog modulation; MIX = combined digital and analog
        %modulation
        function set.Mode(obj, mode)
            arguments
                obj Cobolt_Laser
                mode(1, :) char{mustBeMember(mode, ["CWP", "DIG"])}
            end
            writeline(obj.SPORT, ['@cobasdr ', num2str(strcmp(mode, "DIG"))]);
            if obj.HANDSHAKE
                readline(obj.SPORT);
            end
            if strcmp(mode, "CWP")
                obj.Clear_Faults
            end
        end

        %Get laser mode. Can cause errors if called too quickly after
        %another command as flush may be called while device is still
        %communicating.
        function mode = get.Mode(obj)
            pause(0.1);
            flush(obj.SPORT);
            writeline(obj.SPORT, "@cobasdr?");
            mode = strip(readline(obj.SPORT));
            if str2double(mode)
                mode = "DIG";
            else
                mode = "CWP";
            end
            %obj.Mode = mode;
        end

        function delete(obj)
            try
                obj.Set_keyEnabled(true) %reactivate keyswitch
                obj.Clear_Faults();
                obj.Start() %Set to on, so laser can be controlled just with key.
                %delete(obj.SPORT);
            catch
            end
        end
    end
end
