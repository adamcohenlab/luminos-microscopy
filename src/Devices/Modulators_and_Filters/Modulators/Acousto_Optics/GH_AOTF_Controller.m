classdef GH_AOTF_Controller < Device
    %-------------------------------------------------------------------
    %Controller class for 8-channel Gooch & Housego AOTF controllers.
    %Allows Serial control of AOTFs, including setting the AOTF into
    % external or internal modulation mode. IMPORTANT: External analog
    % modulation of the AOTF is applied based on the internal AMP setting.
    % The external modulation controls what percentage of the internal AMP
    % setting is achieved, from 0% to 100%.
    % This class is not necessary if one always uses the AOTF with pure
    % external modulation and no changes to the AOTF config from other
    % software, but if used, it does ensure that any changes made to the
    % AOTF config by other software are reverted to the desired config for
    % use by the Matlab RigControl.
    %------------------------------------------------------------------
    properties (Transient)
        %Initialization parameters
        ChannelStates
        ChannelFrequencies
        ChannelPhases
        ChannelPow
        initialize_on_startup

        device
        params
        %Power calibration gives correspondence between AMP level (0-1023,
        %first row) and ouput power (mW, second row). This is taken from
        %the driver manual, but if desired, could be more accurately
        %determined manually. Can specify custom curve in initializer.
        Power_calibration_curve = [0, 100, 200, 300, 400, 500, 600, 700, 800, 900, 1000, 1023; 0, 5, 10, 25, 30, 70, 100, 135, 180, 225, 280, 300];
        NUMCHANNELS %number of channels used on controller
        %         amod DQ_AO_On_Demand
        COMPORT
    end
    properties
        Modes = strings;
        Freqs;
        Amps; %Percentage
        Phases;
    end
    methods
        function obj = GH_AOTF_Controller(Initializer)
            obj@Device(Initializer);
            obj.NUMCHANNELS = obj.Initializer.NUMCHANNELS;
            obj.COMPORT = obj.Initializer.COMPORT;
            %apply custom calibration curve if specified
            if ~isempty(obj.Initializer.Power_calibration_curve)
                obj.Power_calibration_curve = obj.Initializer.Power_calibration_curve;
            end
            obj.device = serialport(obj.COMPORT, 9600, 'Parity', "none", ...
                'StopBits', 1, 'FlowControl', "none", 'DataBits', 8, 'Timeout', obj.port_timeout);
            configureTerminator(obj.device, "CR");
            flush(obj.device);

            if Initializer.initialize_on_startup %if desired, initialize to specified state.
                for channel = 1:obj.NUMCHANNELS
                    obj.Set_Mode(channel, Initializer.ChannelStates(channel));
                    obj.Set_Frequency(channel, Initializer.ChannelFrequencies(channel));
                    obj.Set_Phase(channel, Initializer.ChannelPhases(channel));
                    obj.Set_Power(channel, Initializer.ChannelPow(channel));
                end
            end
            for channel = 1:obj.NUMCHANNELS
                [obj.Modes(channel), obj.Freqs(channel), obj.Amps(channel), obj.Phases(channel)] = obj.Get_State(channel);
            end
        end

        %Use the serial connection to modulate the selected channel based
        % on percentage. level should be a number between 0 and 100. This function does not set
        %the modulation state, so the client must ensure that the
        %modulation state is appropriately set to "Int". This sets the
        %maximum level corresponding to a 5V input in external modulation
        %mode as well.
        function Set_Amp_Percent(obj, channel, level)
            if (channel <= 0) || (channel > obj.NUMCHANNELS)
                error("Invalid AOTF channel. Must be between 1 and %d", obj.NUMCHANNELS);
            end
            flush(obj.device);
            if (level <= 100 && level >= 0)
                power = round(level/100*1023);
                %writeline(obj.device,"on");
                writeline(obj.device, ['ch', num2str(channel)]);
                writeline(obj.device, ['am', num2str(power)]);
            else
                warning('Power out of range 0-100. Ignoring')
            end
            [obj.Modes(channel, :), obj.Freqs(channel, :), obj.Amps(channel, :), obj.Phases(channel, :)] = obj.Get_State(channel);
        end

        %Use the serial connection to modulate the selected channel based
        % on RF power. level should be a number between 0 and 300 (mW).
        %This function does not set
        %the modulation state, so the client must ensure that the
        %modulation state is appropriately set to "Int". This sets the
        %maximum level corresponding to a 5V input in external modulation
        %mode as well.
        function Set_Power(obj, channel, level)
            if (channel <= 0) || (channel > obj.NUMCHANNELS)
                error("Invalid AOTF channel. Must be between 1 and %d", obj.NUMCHANNELS);
            end
            flush(obj.device);
            if (level <= 300 && level >= 0)
                %convert desired power to amplitude:
                amp = interp1(obj.Power_calibration_curve(2, :), obj.Power_calibration_curve(1, :), level);
                writeline(obj.device, ['ch', num2str(channel)]);
                writeline(obj.device, ['am', num2str(amp)]);
            else
                warning('Power out of range 0-100. Ignoring')
            end
            [obj.Modes(channel, :), obj.Freqs(channel, :), obj.Amps(channel, :), obj.Phases(channel, :)] = obj.Get_State(channel);
        end

        %         function Analog_Modulate(obj,level)
        %             flush(obj.device);
        %             writeline(obj.device,"mod");
        %             obj.amod.OD_Write(level);
        %         end

        %Set the frequency (in MHz) of the selected channel. Should be
        %between 40 and 150.
        function Set_Frequency(obj, channel, freq)
            if (channel <= 0) || (channel > obj.NUMCHANNELS)
                error("Invalid AOTF channel. Must be between 1 and %d", obj.NUMCHANNELS);
            elseif (freq < 40) || (freq > 150)
                warning("AOTF frequency must be between 40 and 150 MHz");
                return
            end
            flush(obj.device);
            writeline(obj.device, ['ch', num2str(channel)]);
            writeline(obj.device, ['fr', num2str(freq)]);
            [obj.Modes(channel, :), obj.Freqs(channel, :), obj.Amps(channel, :), obj.Phases(channel, :)] = obj.Get_State(channel);
        end

        %Set the phase of the selected channel. Should be
        %between 0 and 16383, representing phase from 0 to 2pi. Only
        %required if frequency has regular spacing.
        function Set_Phase(obj, channel, phase)
            if (channel <= 0) || (channel > obj.NUMCHANNELS)
                error("Invalid AOTF channel. Must be between 1 and %d", obj.NUMCHANNELS);
            elseif (phase < 0) || (phase > 16383)
                warning("AOTF phase must be between 0 and 16383 MHz");
                return
            end
            flush(obj.device);
            writeline(obj.device, ['ch', num2str(channel)]);
            writeline(obj.device, ['ph', num2str(phase)]);
            [obj.Modes(channel, :), obj.Freqs(channel, :), obj.Amps(channel, :), obj.Phases(channel, :)] = obj.Get_State(channel);
        end

        %This function will return the current
        %frequency, amplitude, phase, and modulation mode of the selected
        %channel.
        function [mode, freq, amp, phase] = Get_State(obj, channel)
            if (channel <= 0) || (channel > obj.NUMCHANNELS)
                error("Invalid AOTF channel. Must be between 1 and %d", obj.NUMCHANNELS);
            end
            flush(obj.device);

            writeline(obj.device, ['ch', num2str(channel)]);
            writeline(obj.device, "st");
            mode = split(readline(obj.device), {'(', ')'});
            mode = upper(mode(2));

            freq = split(readline(obj.device));
            freq = str2double(freq(2));

            amp = split(readline(obj.device));
            amp = 100 * str2double(amp(2)) / 1023;

            phase = split(readline(obj.device));
            phase = str2double(phase(2));

        end

        %This function enables choosing the modulation mode of the selected
        %channel. Internal mode allows for serial port control of the
        %channel modulation. External allows for DAQ analog control via the
        %BNC inputs. In both modes, external digital modulation via the
        %digital BNC inputs is active. Off mode turns the selected channel
        %off, regardless of external analog or digital input states.
        function Set_Mode(obj, channel, mode)
            arguments
                obj GH_AOTF_Controller
                channel(1, 1) {mustBeInteger(channel)}
                mode(1, :) char{mustBeMember(mode, ["Int", "INT", "Ext", "EXT", "Off", "OFF"])}

            end
            if (channel <= 0) || (channel > obj.NUMCHANNELS)
                error("Invalid AOTF channel. Must be between 1 and %d", obj.NUMCHANNELS);
            end
            writeline(obj.device, ['ch', num2str(channel)]);
            if ismember(mode, ["Int", "INT"])
                writeline(obj.device, "on"); %Deactivate external analog modulation and activate serial control
            elseif ismember(mode, ["Ext", "EXT"])
                writeline(obj.device, "mod"); %Enable external analog modulation
            elseif ismember(mode, ["Off", "OFF"])
                writeline(obj.device, "off"); %Turn channel off
            end
            [obj.Modes(channel, :), obj.Freqs(channel, :), obj.Amps(channel, :), obj.Phases(channel, :)] = obj.Get_State(channel);
        end

    end
end