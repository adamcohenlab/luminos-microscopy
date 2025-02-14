classdef Scientifica_Stage_Controller < Linear_Controller
    properties (Constant, Hidden)
        nonblockingMoveCompletedDetectionStrategy = 'poll';
    end
    properties (Transient)
        limits
        % speed
        mode
        axes
        serial_com internal.Serialport
        COMPORT string
    end
    properties
        microstep_size
        driver string
        baud
        pos_command string
        %current_position
    end
    properties (SetObservable, AbortSet)
        pos % x, y, z
    end
    
    properties (Hidden, Constant)
        defaultVelocityStart = 5000; %Default value for /all/ stage types
        defaultAcceleration = 500; %Default value for /all/ stage types
    end
    methods
        
        function obj = Scientifica_Stage_Controller(Initializers)
            lscSerialArgs = {'defaultTerminator', 'CR', 'deviceErrorResp', 'E', ...
                'deviceSimpleResp', 'A'};
            lscArgs = {'numDeviceDimensions', 3};
            obj = obj@Linear_Controller(Initializers);
            obj.COMPORT = obj.Initializer.COMPORT;
            obj.driver = obj.Initializer.driver;
            if strcmp(obj.driver, 'Motion1')
                obj.baud = 9600;
                obj.pos_command = 'POS';
            elseif strcmp(obj.driver, 'Motion2')
                obj.baud = 38400;
                obj.pos_command = 'P';
            else
                error('Unknown driver');
            end
            obj.Configure_Controller();
        end

        function Configure_Controller(obj)
            obj.serial_com = serialport(obj.COMPORT, obj.baud, 'Timeout', obj.port_timeout);
            obj.serial_com.configureTerminator("CR");
            set(obj.serial_com, 'DataBits', 8);
            set(obj.serial_com, 'FlowControl', 'none');
            set(obj.serial_com, 'Parity', 'none');
            set(obj.serial_com, 'StopBits', 1);
            set(obj.serial_com, 'Timeout', 0.1);
        end

        function success = Move_To_Position(obj, position)
            % position = [x,y,z]
            flush(obj.serial_com);
            obj.serial_com.writeline(['ABS ', num2str(round(position / obj.microstep_size))]);
            msg = obj.serial_com.readline();

            while obj.isMoving()
                pause(.01);
            end
            success = 1; % TODO (but not too important): read msg to see if move was successful
        end

        function pos = Get_Current_Position_Microns(obj)
            flush(obj.serial_com);
            pause(.01)
            obj.serial_com.writeline(obj.pos_command);
            flush(obj.serial_com);
            pos_res = obj.serial_com.readline();
            % Error handling when serial timeout
            if isstring(pos_res)
                pos_str = str2num(pos_res);
                pos.x = pos_str(1);
                pos.y = pos_str(2);
                if size(pos_str, 2) == 3
                    pos.z = pos_str(3);
                else
                    pos.z = obj.pos.z;
                end
            else
                pos.x = obj.pos.x;
                pos.y = obj.pos.y;
                pos.z = obj.pos.z;
            end
        end
        
        function pos = get.pos(obj)
            pos = obj.Get_Current_Position_Microns();
            %obj.pos = pos;
        end
        
        function res = Step_Fixed(obj, dim, distance_um)
            flush(obj.serial_com);
            dimvec = zeros(1, 3);
            dimvec(dim) = 1;
            stepvec = dimvec * round(distance_um/obj.microstep_size);
            obj.serial_com.writeline(['REL ', num2str(stepvec)]);
            r1 = obj.serial_com.readline();
            while (obj.isMoving())
                pause(.1);
            end
            res = r1;
        end
        function tf = isMoving(obj)
            flush(obj.serial_com);
            obj.serial_com.writeline('S');
            res = obj.serial_com.readline();
            if isnan(str2double(res))
                tf = true;
            else
                tf = logical(str2double(res));
            end
        end
    end
end