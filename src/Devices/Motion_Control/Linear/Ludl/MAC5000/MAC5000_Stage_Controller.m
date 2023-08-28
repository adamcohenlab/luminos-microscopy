%%April 2022 Phil Brooks
%%Motor controller implemented, allowing for an arbitrary
%%number of motor axes.
classdef MAC5000_Stage_Controller < Linear_Controller
    properties (Transient)
        axes
        serial_com internal.Serialport
        COMPORT string
        microstep_size = 0.2;
    end
    properties (SetAccess = private)
        %current_position can't be guaranteed unless we wait until movement
        %is done after every move command. This would have an impact on
        %timing of calling clients, so is not a good solution. If client
        %wants position, client should call Get_Position() method.
        % pos
    end
    
    properties
        pos
    end
    
    methods
        function obj = MAC5000_Stage_Controller(Initializers)
            obj@Linear_Controller(Initializers)
            obj.COMPORT = obj.Initializer.COMPORT;
            obj.Configure_Controller();
        end
        
        %To be called as final step of initialization.
        function Configure_Controller(obj)
            obj.serial_com = serialport(obj.COMPORT, 9600, 'Timeout', obj.port_timeout);
            configureTerminator(obj.serial_com, "LF", "CR"); %Command terminates with CR, reply terminates with LF
            set(obj.serial_com, 'DataBits', 8);
            set(obj.serial_com, 'FlowControl', 'none');
            set(obj.serial_com, 'Parity', 'none');
            set(obj.serial_com, 'StopBits', 2);
            set(obj.serial_com, 'Timeout', 10);
            %Set to high-level control format
            obj.serial_com.write(255, 'uint8');
            obj.serial_com.write(65, 'uint8');
            obj.axes = Get_Axes(obj);
        end
        
        %Returns information about installed controller units. The address
        %fields can be used for low-level control (not implemented
        %currently in this class), the label denotes the type of controller
        %(e.g. EMOT denotes a motor axis controller), the ID gives the
        %single character ID required to designate that axis in high-level
        %controller mode, and the Description gives a user-readable
        %description of that controller.
        function axes = Get_Axes(obj)
            flush(obj.serial_com);
            obj.serial_com.writeline("RCONFIG");
            for i = 1:5
                line = strip(obj.serial_com.readline()); %Read through headers and blank lines and get first axis line
            end
            a = 1;
            while ~(strcmp(line, ":A"))
                fields = split(line);
                axes(a).Address = fields(1);
                axes(a).Label = fields(2);
                axes(a).ID = fields(3);
                axes(a).Description = join(fields(4:end));
                line = strip(obj.serial_com.readline());
                a = a + 1;
            end
        end
        
        function pos = get.pos(obj)
            pos_arr = obj.Get_Current_Position();
            pos.x = pos_arr(1);
            pos.y = pos_arr(2);
            obj.pos = pos;
        end
        
        %Check whether any axis is currently moving (useful for checking
        %before sending next command or before checking position). If
        %called with only the object argument, it returns 1 if any axis is
        %moving, 0 if all axes are stopped. If called with an additional
        %argument (string, char array, or string array, e.g. 'X',"X", or
        %["X","Y"], it will query the axes specified, returning 1 if any of
        %the specified axes are moving. The IDs specified must match the
        %IDs given in the obj.axes property (case insensitive).
        function isMoving = Get_Status(obj, IDs)
            if ~exist('IDs', 'var')
                IDs = {};
                for i = 1:numel(obj.axes)
                    if strlength(obj.axes(i).ID) == 1
                        IDs{end+1} = char(obj.axes(i).ID);
                    end
                end
            else
                IDs = reshape(num2cell(char(IDs)), 1, []); %This line ensures that any input format ('XY',"XY",["X","Y"]) works for IDs.
            end
            flush(obj.serial_com);
            if nargin == 1
                obj.serial_com.writeline("STATUS");
                
            elseif nargin == 2
                IDs = reshape(num2cell(char(IDs)), 1, []); %This line ensures that any input format ('XY',"XY",["X","Y"]) works for IDs.
                message = strcat("STATUS ", join(IDs));
                obj.serial_com.writeline(message);
            end
            reply = obj.serial_com.read(1, 'char');
            switch reply
                case 'N'
                    isMoving = false;
                case 'B'
                    isMoving = true;
                otherwise
                    error("Invalid status request: Check that Device IDs match IDs in axes property")
            end
        end
        
        
        %%Move motor axes specified by IDs array to absolute position (in um) specified by position array.
        %Position should be specified as a distance in um and will be rounded to the
        % nearest multiple of the microstep_size. This
        %method completes the move using a constant, independent speed for each axis.
        %The movements start at the same time, but may finish at different
        %times depending on the individual axis speed and distance to
        %travel.
        function Move_To_Position(obj, position)
            % keep only x, y
            position = position(1:2);
            flush(obj.serial_com);
            IDs = {'X', 'Y'};
            message = join(["MOVE", strcat(IDs, "=", string(round(position./obj.microstep_size)))]);
            obj.serial_com.writeline(message);
            obj.error_check();
            
        end
        %%Move motor axes specified by IDs array to absolute position specified by position array.
        %Position should be specified as an integer number of pulses. This
        %method completes the move using a constant, independent speed for each axis.
        %The movements start at the same time, but may finish at different
        %times depending on the individual axis speed and distance to
        %travel.
        function Move_Absolute_Microsteps(obj, IDs, position)
            flush(obj.serial_com);
            assert(numel(char(IDs)) == numel(position), "number of axis IDs must match dimension of position argument");
            IDs = reshape(num2cell(char(IDs)), 1, []); %This line ensures that any input format ('XY',"XY",["X","Y"]) works for IDs.
            message = join(["MOVE", strcat(IDs, "=", string(round(position)))]);
            obj.serial_com.writeline(message);
            obj.error_check();
        end
        
        %%Not working?
        % Move motor axes specified by IDs array to absolute position (in um) specified by position array.
        %Position should be specified as a distance in um and will be rounded to the
        % nearest multiple of the microstep_size. This
        %method completes the move using a constant linear speed along the
        %vector from the start to the end position.
        %The individual axis movements start and end at the same time.
        function Move_Absolute_Vector(obj, IDs, position_um, speed_um, starting_speed_um)
            arguments
                obj MAC5000_Stage_Controller
                IDs
                position_um
                speed_um(1, 1) {mustBePositive} = 5000
                starting_speed_um(1, 1) {mustBeNonnegative} = 1000
            end
            obj.Move_Absolute_Vector_Microsteps(IDs, position_um./obj.microstep_size, speed_um./obj.microstep_size(1), starting_speed_um/obj.microstep_size(1))
            %             flush(obj.serial_com);
            %             assert(numel(char(IDs))==numel(position_um),"number of axis IDs must match dimension of position argument");
            %             IDs = reshape(num2cell(char(IDs)),1,[]); %This line ensures that any input format ('XY',"XY",["X","Y"]) works for IDs.
            %             message = join(["VMOVE",strcat(IDs,"=",string(round(position_um./obj.microstep_size)))]);
            %             obj.serial_com.writeline(message);
            %             obj.error_check();
        end
        %%Not working?
        % Move motor axes specified by IDs array to absolute position specified by position array.
        %Position should be specified as an integer number of pulses. This
        %method completes the move using a constant linear speed along the
        %vector from the start to the end position.
        %The individual axis movements start and end at the same time.
        function Move_Absolute_Vector_Microsteps(obj, IDs, position, speed, starting_speed)
            arguments
                obj MAC5000_Stage_Controller
                IDs
                position
                speed(1, 1) {mustBePositive} = 25000
                starting_speed(1, 1) {mustBeNonnegative} = 5000
            end
            obj.serial_com.writeline(sprintf("WRITE X97=%d X96=%d", round(speed), round(starting_speed)));
            flush(obj.serial_com);
            assert(numel(char(IDs)) == numel(position), "number of axis IDs must match dimension of position argument");
            IDs = reshape(num2cell(char(IDs)), 1, []); %This line ensures that any input format ('XY',"XY",["X","Y"]) works for IDs.
            
            message = join(["VMOVE", strcat(IDs, "=", string(round(position)))]);
            obj.serial_com.writeline(message);
            obj.error_check();
        end
        
        %%Move motor axes specified by IDs array to relative position (in um) specified by position array.
        %Position should be specified as a distance in um and will be rounded to the
        % nearest multiple of the microstep_size. This
        %method completes the move using a constant, independent speed for each axis.
        %The movements start at the same time, but may finish at different
        %times depending on the individual axis speed and distance to
        %travel.
        function Move_Relative(obj, IDs, position_um)
            flush(obj.serial_com);
            assert(numel(char(IDs)) == numel(position_um), "number of axis IDs must match dimension of position argument");
            IDs = reshape(num2cell(char(IDs)), 1, []); %This line ensures that any input format ('XY',"XY",["X","Y"]) works for IDs.
            message = join(["MOVREL", strcat(IDs, "=", string(round(position_um./obj.microstep_size)))]);
            obj.serial_com.writeline(message);
            obj.error_check();
        end
        %%Move motor axes specified by IDs array to relative position specified by position array.
        %Position should be specified as an integer number of pulses. This
        %method completes the move using a constant, independent speed for each axis.
        %The movements start at the same time, but may finish at different
        %times depending on the individual axis speed and distance to
        %travel.
        function Move_Relative_Microsteps(obj, IDs, position)
            flush(obj.serial_com);
            assert(numel(char(IDs)) == numel(position), "number of axis IDs must match dimension of position argument");
            IDs = reshape(num2cell(char(IDs)), 1, []); %This line ensures that any input format ('XY',"XY",["X","Y"]) works for IDs.
            message = join(["MOVREL", strcat(IDs, "=", string(round(position)))]);
            obj.serial_com.writeline(message);
            obj.error_check();
        end
        
        function pos = Get_Current_Position(obj)
            pos = obj.Get_Current_Position_Microsteps() .* obj.microstep_size;
        end
        function pos = Get_Current_Position_Microsteps(obj)
            obj.serial_com.flush();
            while (obj.Get_Status()) %Wait until motor stops moving
            end
            message = strcat("WHERE ", strcat(obj.axes.ID));
            obj.serial_com.writeline(message);
            line = obj.serial_com.readline();
            pos = split(strip(line));
            pos = str2double(pos(2:end))';
        end
        
        %Configure movement steady-state speed.
        %omitted speeds argument will cause that parameter to be set to a
        %default value (speed = 5000um/s)
        %Speed is in units of um/s. Exact speed set may not be the
        %requested speed due to limits on speed resolution steps, so call
        %a Get_Speed method to check after setting if precision is
        %required.
        function Set_Speed(obj, IDs, speeds)
            IDs = reshape(num2cell(char(IDs)), 1, []); %This line ensures that any input format ('XY',"XY",["X","Y"]) works for IDs.
            if nargin == 2
                speeds = 5000 * ones(1, numel(IDs));
            end
            speeds = speeds ./ obj.microstep_size;
            Set_Speed_Microsteps(obj, IDs, speeds);
        end
        %Configure movement steady-state speed.
        %omitted speeds argument will cause that parameter to be set to a
        %default value (speed = 25000Hz)
        %Speed is in units of microsteps/s. Exact speed set may not be the
        %requested speed due to limits on speed resolution steps, so call
        %a Get_Speed method to check after setting if precision is
        %required.
        function Set_Speed_Microsteps(obj, IDs, speeds)
            IDs = reshape(num2cell(char(IDs)), 1, []); %This line ensures that any input format ('XY',"XY",["X","Y"]) works for IDs.
            if nargin == 2
                speeds = 25000 * ones(1, numel(IDs));
            end
            assert(numel(IDs) == numel(speeds), "number of axis IDs must match dimension of speeds argument");
            flush(obj.serial_com);
            message = join(["SPEED", strcat(IDs, '=', string(round(speeds)))]);
            obj.serial_com.writeline(message);
            obj.error_check();
        end
        
        %Configure movement starting speed (initial speed before ramp to
        %steady-state)
        %omitted speeds argument will cause that parameter to be set to a
        %default value (speed = 1000/s)
        %Speed is in units of um/s. Exact speed set may not be the
        %requested speed due to limits on speed resolution steps, so call
        %a Get_Starting_Speed method to check after setting if precision is
        %required.
        function Set_Starting_Speed(obj, IDs, speeds)
            IDs = reshape(num2cell(char(IDs)), 1, []); %This line ensures that any input format ('XY',"XY",["X","Y"]) works for IDs.
            if nargin == 2
                speeds = 1000 * ones(1, numel(IDs));
            end
            speeds = speeds ./ obj.microstep_size;
            Set_Starting_Speed_Microsteps(obj, IDs, speeds);
        end
        %Configure movement starting speed.(initial speed before ramp to
        %steady-state)
        %omitted speeds argument will cause that parameter to be set to a
        %default value (speed = 5000Hz)
        %Speed is in units of microsteps/s. Exact speed set may not be the
        %requested speed due to limits on speed resolution steps, so call
        %a Get_Starting_Speed method to check after setting if precision is
        %required.
        function Set_Starting_Speed_Microsteps(obj, IDs, speeds)
            IDs = reshape(num2cell(char(IDs)), 1, []); %This line ensures that any input format ('XY',"XY",["X","Y"]) works for IDs.
            if nargin == 2
                speeds = 5000 * ones(1, numel(IDs));
            end
            assert(numel(IDs) == numel(speeds), "number of axis IDs must match dimension of speeds argument");
            flush(obj.serial_com);
            message = join(["STSPEED", strcat(IDs, '=', string(round(speeds)))]);
            obj.serial_com.writeline(message);
            obj.error_check();
        end
        
        %Set Acceleration (ramp time between starting and steady-state
        %speeds). Acceleration values are on a scale from 1(fast ramp) to
        %255(slow ramp), with arbitrary units. Omitted acceleration
        %argument will cause parameter to be set to default of 20.
        function Set_Accel(obj, IDs, accels)
            IDs = reshape(num2cell(char(IDs)), 1, []); %This line ensures that any input format ('XY',"XY",["X","Y"]) works for IDs.
            if nargin == 2
                accels = 20 * ones(1, numel(IDs));
            end
            assert(numel(IDs) == numel(accels), "number of axis IDs must match dimension of speeds argument");
            
            assert(all(accels >= 1 & accels <= 255), "Acceleration values must be between 1 and 255");
            flush(obj.serial_com);
            message = join(["ACCEL", strcat(IDs, '=', string(round(accels)))]);
            obj.serial_com.writeline(message);
            obj.error_check();
        end
        
        %Return axis speed for all axes.
        function speed = Get_Speed(obj)
            speed = obj.Get_Speed_Microsteps() .* obj.microstep_size;
        end
        function speed = Get_Speed_Microsteps(obj)
            obj.serial_com.flush();
            message = strcat("SPEED ", strcat(obj.axes.ID));
            obj.serial_com.writeline(message);
            line = obj.serial_com.readline();
            speed = split(strip(line));
            speed = str2double(speed(2:end))';
        end
        
        %Return initial axis speed for all axes.
        function speed = Get_Starting_Speed(obj)
            speed = obj.Get_Starting_Speed_Microsteps() .* obj.microstep_size;
        end
        function speed = Get_Starting_Speed_Microsteps(obj)
            obj.serial_com.flush();
            message = strcat("STSPEED ", strcat(obj.axes.ID));
            obj.serial_com.writeline(message);
            line = obj.serial_com.readline();
            speed = split(strip(line));
            speed = str2double(speed(2:end))';
        end
        
        %Return axis acceleration (1-255 arbitrary scale) for all axes.
        %1 is fastest (shortest ramp time). 255 is slowest (longest ramp)
        function speed = Get_Accel(obj)
            obj.serial_com.flush();
            message = strcat("ACCEL ", strcat(obj.axes.ID));
            obj.serial_com.writeline(message);
            line = obj.serial_com.readline();
            speed = split(strip(line));
            speed = str2double(speed(2:end))';
        end
        
        %Sets current stage position as the origin on the axes specified by
        %IDs
        function Set_Zero(obj, IDs)
            flush(obj.serial_com);
            IDs = reshape(num2cell(char(IDs)), 1, []); %This line ensures that any input format ('XY',"XY",["X","Y"]) works for IDs.
            message = join(["HERE", strcat(IDs, "=0")]);
            obj.serial_com.writeline(message);
            obj.error_check();
        end
        %Only run if you have ensured that stage can freely move to axis
        %limits without running into objectives or anything else. Finds
        %axis limits and then moves stage to position midway between
        %limits, setting this to the origin (0).
        function Reset_Zero(obj)
            obj.serial_com.writeline("CALIB S");
            obj.serial_com.readline();
        end
        
        function disable_joystick(obj, IDs)
            if nargin == 1
                IDs = strcat(obj.axes.ID);
            end
            flush(obj.serial_com);
            IDs = reshape(num2cell(char(IDs)), 1, []); %This line ensures that any input format ('XY',"XY",["X","Y"]) works for IDs.
            message = join(["JOYSTICK", strcat(IDs, "-")]);
            obj.serial_com.writeline(message);
            obj.error_check();
        end
        function enable_joystick(obj, IDs)
            if nargin == 1
                IDs = strcat(obj.axes.ID);
            end
            flush(obj.serial_com);
            IDs = reshape(num2cell(char(IDs)), 1, []); %This line ensures that any input format ('XY',"XY",["X","Y"]) works for IDs.
            message = join(["JOYSTICK", strcat(IDs, "+")]);
            obj.serial_com.writeline(message);
            obj.error_check();
        end
    end
    methods (Access = protected)
        function error = error_check(obj)
            reply = readline(obj.serial_com);
            fields = split(strip(reply));
            if strcmp(fields(1), ':A')
                error = 0;
                return
            else
                error = str2num(fields(2));
                switch error
                    case -1
                        warning("Warning: Ludl stage: Unknown command");
                    case -2
                        warning("Warning: Ludl stage: Illegal point type or axis, or module not installed");
                    case -3
                        warning("Warning: Ludl stage: Not enough parameters");
                    case -4
                        warning("Warning: Ludl stage: Parameter out of range");
                    case -21
                        warning("Warning: Ludl stage: Process aborted by HALT command");
                    otherwise
                        warning("Warning: Ludl stage: Unknown error");
                end
                return
            end
        end
    end
end
