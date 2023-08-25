classdef OBIS_Laser < Laser_Device
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
        function obj = OBIS_Laser(Initializer)
            obj@Laser_Device(Initializer);
            obj.COMPORT = obj.Initializer.COMPORT;
            obj.SPORT = serialport(obj.COMPORT, 9600, 'Timeout', obj.port_timeout); %Matlab defaults to appropriate Parity etc.
            configureTerminator(obj.SPORT, "CR"); %Set the terminator to carriage return
            obj.Mode = 'CWP';
            obj.initialize_props();
            obj.Set_IndicatorLight(false); %turn off head indicator led (to reduce light pollution on the table
            obj.get("Mode");
        end

        %This function takes a boolean state which tells it whether the
        %laser head indicator LED should be on (true) or off (false).
        function Set_IndicatorLight(obj, state)
            if ~state
                writeline(obj.SPORT, 'syst:ind:las OFF');
            else
                writeline(obj.SPORT, 'syst:ind:las ON');
            end
            if obj.HANDSHAKE
                readline(obj.SPORT);
            end
        end
        %this function takes a boolean delayon which tells it whether CDRH
        %delay (5 s delay before emission) should be enabled (true) or disabled(false).
        function Set_CDRHdelay(obj, delayon)
            if ~delayon
                writeline(obj.SPORT, 'syst:cdrh OFF');
            else
                writeline(obj.SPORT, 'syst:cdrh ON');
            end
            if obj.HANDSHAKE
                readline(obj.SPORT);
            end
        end

        function Start(obj)
            writeline(obj.SPORT, 'sour:am:stat ON');
            if obj.HANDSHAKE
                readline(obj.SPORT);
            end
        end

        function Stop(obj)
            writeline(obj.SPORT, 'sour:am:stat OFF');
            if obj.HANDSHAKE
                readline(obj.SPORT);
            end
        end

        function state = Get_state(obj)
            flush(obj.SPORT);
            writeline(obj.SPORT, 'sour:am:stat ?');
            state = strip(readline(obj.SPORT));
            state = strcmp(state, 'ON');
            if obj.HANDSHAKE
                readline(obj.SPORT);
            end
        end
        function wavelength = Get_wav(obj)
            flush(obj.SPORT);
            writeline(obj.SPORT, "syst:inf:wav?");
            wavelength = str2double(readline(obj.SPORT));
            if obj.HANDSHAKE
                readline(obj.SPORT);
            end
        end
        function power_rating = Get_powRating(obj)
            flush(obj.SPORT);
            writeline(obj.SPORT, "syst:inf:pow?");
            power_rating = str2double(readline(obj.SPORT));
            if obj.HANDSHAKE
                readline(obj.SPORT);
            end
        end
        %Nominal and rating power are typically the same. See manual for
        %details
        %         function nominal_power = Get_powNom(obj)
        %             flush(obj.SPORT);
        %             writeline(obj.SPORT,"sour:pow:nom?");
        %             nominal_power = str2double(readline(obj.SPORT));
        %         end
        function limits = Get_powLimits(obj)
            limits = [-1, -1];
            flush(obj.SPORT);
            writeline(obj.SPORT, "sour:pow:lim:low?");
            limits(1) = str2double(readline(obj.SPORT));
            if obj.HANDSHAKE
                readline(obj.SPORT);
            end
            writeline(obj.SPORT, "sour:pow:lim:high?");
            limits(2) = str2double(readline(obj.SPORT));
            if obj.HANDSHAKE
                readline(obj.SPORT);
            end
        end
        %return current head output power in Watts
        function power = Get_pow(obj)
            flush(obj.SPORT);
            writeline(obj.SPORT, "sour:pow:lev?");
            power = str2double(readline(obj.SPORT));
            if obj.HANDSHAKE
                readline(obj.SPORT);
            end
        end

        %return current output power setting in Watts (may not be the
        %actual power output, and will return the setting even if laser is off).
        function power = Get_pow_set(obj)
            flush(obj.SPORT);
            writeline(obj.SPORT, "sour:pow:lev:imm:ampl?");
            power = str2double(readline(obj.SPORT));
            if obj.HANDSHAKE
                readline(obj.SPORT);
            end
        end

        %Set laser output power setting in Watts. Does not turn laser on.
        function Set_pow(obj, pow)
            writeline(obj.SPORT, ['sour:pow:lev:imm:ampl ', num2str(pow)])
            if obj.HANDSHAKE
                readline(obj.SPORT);
            end
        end

        %return boolean specifying whether laser is enabled by key and
        %interlock. true = laser enabled. false = key or interlock off.
        function enabled = Get_interlockStatus(obj)
            flush(obj.SPORT);
            writeline(obj.SPORT, "syst:lock?");
            enabled = strcmp(strip(readline(obj.SPORT)), "ON");
            if obj.HANDSHAKE
                readline(obj.SPORT);
            end
        end


        %This method allows the client to get a list of the available modes
        function modes = Get_available_modes(obj)
            modes = ["CWP", "CWC", "DIGITAL", "ANALOG", "MIXED"];
        end

        %sets operating mode of laser: CWP = constant power; CWC =
        %constant current; DIG = external digital modulation; ANAL =
        %external analog modulation; MIX = combined digital and analog
        %modulation
        function set.Mode(obj, mode)
            arguments
                obj OBIS_Laser
                mode(1, :) char{mustBeMember(mode, ["CWP", "CWC", "DIGITAL", "ANALOG", "MIXED"])}
            end
            if ismember(mode, {'CWP', 'CWC'})
                writeline(obj.SPORT, ['sour:am:int ', mode]);
            else
                writeline(obj.SPORT, ['sour:am:ext ', mode]);
            end
            if obj.HANDSHAKE
                readline(obj.SPORT);
            end
        end

        function mode = get.Mode(obj)
            flush(obj.SPORT);
            writeline(obj.SPORT, "sour:am:sour?");
            mode = strip(readline(obj.SPORT));
            if obj.HANDSHAKE
                readline(obj.SPORT);
            end
            obj.Mode = mode;
        end

        function delete(obj)
            try
                obj.Stop()
            catch
            end
        end
    end
end
