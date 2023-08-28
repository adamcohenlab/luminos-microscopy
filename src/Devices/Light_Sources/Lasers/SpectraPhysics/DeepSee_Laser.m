classdef DeepSee_Laser < Laser_Device
    properties (Transient)
        SPORT %serial communication
        COMPORT
        HANDSHAKE = false; %Whether or not the device will return a handshake line ("OK") after successful command
        %If HANDSHAKE is true, then the client needs to wait for the
        %handshake before trying to send another command. This can be done
        %by calling readline() on the expected handshake, ignoring the
        %result.
        
        wavelength_limits;
    end
    properties
        wavelength;
    end
    
    methods
        function obj = DeepSee_Laser(Initializer)
            obj@Laser_Device(Initializer);
            obj.COMPORT = obj.Initializer.COMPORT;
            obj.SPORT = serialport(obj.COMPORT, 115200, 'Timeout', obj.port_timeout); %Matlab defaults to appropriate Parity etc.
            configureTerminator(obj.SPORT, "LF"); %Set the terminator to carriage return
            obj.initialize_props();
            obj.wavelength_limits = Get_wavLimits(obj);
        end
        
        %Check status of system during warmup. Returns number from 0 to 100
        %indicating approximate percentage of warmup completed. Laser
        %cannot turn on until 100% warmed up.
        function status = Get_WarmingStatus(obj)
            writeline(obj.SPORT, 'READ:PCTWarmedup?');
            status = uint8(str2double(readline(obj.SPORT)));
            if obj.HANDSHAKE
                readline(obj.SPORT);
            end
        end
        %If system warmed up, turns pump diodes on. Otherwise no effect.
        function Start(obj)
            if Get_WarmingStatus < 100
                warning('DeepSee not warmed up. Wait until warmed up to start');
                return;
            else
                writeline(obj.SPORT, 'ON');
                if obj.HANDSHAKE
                    readline(obj.SPORT);
                end
            end
        end
        
        %Turns off pump diodes and closes shutter
        function Stop(obj)
            writeline(obj.SPORT, 'OFF');
            if obj.HANDSHAKE
                readline(obj.SPORT);
            end
        end
        
        %Opens the main shutter
        function Open_shutter(obj)
            writeline(obj.SPORT, 'SHUT 1')
            if obj.HANDSHAKE
                readline(obj.SPORT);
            end
        end
        
        %Closes the main shutter
        function Close_shutter(obj)
            writeline(obj.SPORT, 'SHUT 0')
            if obj.HANDSHAKE
                readline(obj.SPORT);
            end
        end
        
        %Reads and returns shutter status. The actual flag controls whether
        %the value returned corresponds to the last shutter command sent to
        %the laser (actual == false) or to the actual state of the shutter
        %(actual == true). When using the (actual==true) option, be aware
        %that the state returned may be incorrect for approximately 1
        %second after issuing the Open_shutter() command.
        function isOpen = Get_shutterStatus(obj, actual = false)
            flush(obj.SPORT)
            if actual
                %Actual shutter position (may be incorrect within 1 sec
                %after shutter open command).
                writeline(obj.SPORT, "STB?");
                isOpen = str2double(readline(obj.SPORT));
            else
                %Last shutter command sent to laser
                writeline(obj.SPORT, "SHUT?");
                isOpen = str2double(readline(obj.SPORT));
            end
            if obj.HANDSHAKE
                readline(obj.SPORT);
            end
        end
        
        %Returns hex value that corresponds with a 32 bit binary number.
        %See manual for details of status bits.
        function hex_state = Get_state(obj)
            flush(obj.SPORT);
            writeline(obj.SPORT, '*STB?');
            hex_state = strip(readline(obj.SPORT));
            if obj.HANDSHAKE
                readline(obj.SPORT);
            end
        end
        
        %Read current wavelength (nm).
        function wavelength = Get_wav(obj)
            flush(obj.SPORT);
            writeline(obj.SPORT, "READ:WAV?");
            wavelength = str2double(readline(obj.SPORT));
            if obj.HANDSHAKE
                readline(obj.SPORT);
            end
        end
        
        %Get wavelength limits
        function limits = Get_wavLimits(obj)
            limits = [-1, -1];
            flush(obj.SPORT);
            writeline(obj.SPORT, "WAV:MIN?");
            limits(1) = str2double(readline(obj.SPORT));
            if obj.HANDSHAKE
                readline(obj.SPORT);
            end
            writeline(obj.SPORT, "WAV:MAX?");
            limits(2) = str2double(readline(obj.SPORT));
            if obj.HANDSHAKE
                readline(obj.SPORT);
            end
        end
        
        %Set emission wavelength
        function Set_wav(obj, wav)
            if ((wav < obj.wavelength_limits(1)) || (wav > obj.wavelength_limits(2)))
                warning("wavelength must be between %i and %i", obj.wavelength_limits(1), obj.wavelength_limits(2));
                return
            end
            writeline(obj.SPORT, ['WAV ', num2str(wav)])
            if obj.HANDSHAKE
                readline(obj.SPORT);
            end
            obj.wavelength = wav;
        end
        
        %return current output power in Watts
        function power = Get_pow(obj)
            flush(obj.SPORT);
            writeline(obj.SPORT, "READ:POW?");
            power = str2double(readline(obj.SPORT));
            if obj.HANDSHAKE
                readline(obj.SPORT);
            end
        end
        
        %Shut down laser. Saves internal variables and prepares for
        %shutdown. Only call this when done with the laser for the day as
        %startup takes >30min
        function Shutdown(obj)
            writeline(obj.SPORT, 'SHUTDOWN')
            if obj.HANDSHAKE
                readline(obj.SPORT);
            end
        end
    end
end
