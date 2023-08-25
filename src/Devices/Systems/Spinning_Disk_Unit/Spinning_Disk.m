classdef Spinning_Disk < Device
    properties (Transient)
        COMPORT
        SPORT %serial communication
        MINSPEED = 0;
        MAXSPEED
    end
    %------------------------------------------------------------------------
    % IMPORTANT NOTE: Although it might be tempting to want the various 'set'
    % commands to return the new value to which the speed is set, this is not a
    % good idea with this hardware. Due to inertia, the wheel takes some time
    % to settle down to the new stable speed. If the speed is queried too soon
    % after the 'set' command, the result will be some unstable transition
    % speed. The best alternative is to wait a fraction of a second (I haven't
    % tested extensively, but 0.5s is probably enough) and then call
    % GetSpeed(). This is not built-in because including pause() commands here
    % could cause bad consequences to a client.
    %-------------------------------------------------------------------------
    methods
        function obj = Spinning_Disk(Initializer)
            obj@Device(Initializer);
            obj.SPORT = serialport(Initializer.COMPORT, 115200, 'Timeout', obj.port_timeout*2); %Matlab defaults to appropriate Parity etc.
            configureTerminator(obj.SPORT, "CR"); %Set the terminator to carriage return
            flush(obj.SPORT);
            writeline(obj.SPORT, "MS_MAX, ?");
            out = strsplit(strip(readline(obj.SPORT)), ':A');
            obj.MAXSPEED = str2double(out(1));
            obj.MINSPEED = 1500;
            %             %Find min speed by setting to 0 and checking what speed is
            %             SetSpeed(obj,'0');
            %             pause(1); %wait 500ms for speed to stabilize
            %             obj.MINSPEED = max(GetSpeed(obj),0) %ensures that NaN is changed to 0.
        end
        
        function speed = GetSpeed(obj)
            flush(obj.SPORT);
            writeline(obj.SPORT, "MS, ?");
            out = strsplit(strip(readline(obj.SPORT)), ':A');
            speed = str2double(out(1));
        end
        
        %Attempt to set speed to target_speed.
        function SetSpeed(obj, target_speed)
            writeline(obj.SPORT, ['MS, ', num2str(target_speed)]);
            
        end
        
        %Attempt to increment speed by 1rpm.
        function IncSpeed(obj)
            writeline(obj.SPORT, 'MS+');
        end
        
        %Attempt to decrement speed by 1rpm.
        function DecSpeed(obj)
            writeline(obj.SPORT, 'MS-');
        end
        
        %Auto-adjust the disc speed based on the camera exposure time (ms)
        %This ensures that the exposure time is a multiple of the time the
        %disc takes to sweep one frame (30 degrees). This should ideally be
        %called after manually setting the speed to the desired range,
        %although it is less important for relatively long exposures.
        function AutoSpeed(obj, exposure)
            writeline(obj.SPORT, ['MS_ADJUST, ', num2str(exposure)]);
            
        end
        
        %Get vector containing min and max speeds attainable by the disc.
        function limits = GetSpeedLimits(obj)
            limits = [obj.MINSPEED, obj.MAXSPEED];
        end
        
        %start disk rotation
        function Start(obj)
            writeline(obj.SPORT, 'MS_RUN');
            
        end
        
        %stop disk rotation
        function Stop(obj)
            writeline(obj.SPORT, 'MS_STOP');
            
        end
    end
end
