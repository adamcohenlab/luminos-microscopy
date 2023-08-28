classdef Sutter_Stage_Controller < Linear_Controller
    properties (Transient)
        limits
        % speed
        mode
        axes
        serial_com internal.Serialport
        COMPORT string
    end
    properties (SetAccess = private, SetObservable)
        microstep_size
    end
    properties
        %current_position
        pos % {x, y, z}
    end
    methods
        function obj = Sutter_Stage_Controller(Initializers)
            obj@Linear_Controller(Initializers)
            obj.microstep_size = 62.5e-3; %step size in microns
            obj.COMPORT = obj.Initializer.COMPORT;
            obj.Configure_Controller();
        end
        
        function Configure_Controller(obj)
            obj.serial_com = serialport(obj.COMPORT, 128000, 'Timeout', obj.port_timeout);
            configureTerminator(obj.serial_com, "CR");
            set(obj.serial_com, 'DataBits', 8);
            set(obj.serial_com, 'FlowControl', 'none');
            set(obj.serial_com, 'Parity', 'none');
            set(obj.serial_com, 'StopBits', 1);
            set(obj.serial_com, 'Timeout', 10);
        end
        
        function success = Move_To_Position(obj, position)
            x = position(1);
            y = position(2);
            z = position(3);
            flush(obj.serial_com);
            obj.serial_com.write('M', 'uint8');
            obj.serial_com.write(uint32(round(x/obj.microstep_size)), 'uint32');
            obj.serial_com.write(uint32(round(y/obj.microstep_size)), 'uint32');
            obj.serial_com.write(uint32(round(z/obj.microstep_size)), 'uint32');
            msg = obj.serial_com.readline();
            success = 1; % TODO: read msg to see if successful (but not too important)
        end
        
        function Step_Fixed(obj, dim, distance_um)
            flush(obj.serial_com);
            obj.Update_Current_Position_Microns();
            if dim == 1
                obj.Move_To_Position([obj.pos.x + distance_um, obj.pos.y, obj.pos.z]);
            elseif dim == 2
                obj.Move_To_Position([obj.pos.x, obj.pos.y + distance_um, obj.pos.z]);
            elseif dim == 3
                obj.Move_To_Position([obj.pos.x, obj.pos.y, obj.pos.z + distance_um]);
            end
        end
        
        function [xout, yout, zout, msg] = Jog_To_Position(obj, s, x, y, z)
            flush(obj.serial_com);
            if s > 0 && s < 15
                obj.serial_com.write('S', 'uint8');
                obj.serial_com.write(uint8(s), 'uint8');
                pause(.1) %Required pause from Sutter manual
                obj.serial_com.write(uint32(round(x/obj.microstep_size)), 'uint32');
                obj.serial_com.write(uint32(round(y/obj.microstep_size)), 'uint32');
                obj.serial_com.write(uint32(round(z/obj.microstep_size)), 'uint32');
                msg = obj.serial_com.readline();
            else
                warning('Illegal Speed. (Allowed Range 1-15). Select allowed value and try again.')
            end
        end
        
        function pos = get.pos(obj)
            pos = obj.Get_Current_Position_Microns();
            obj.pos = pos;
        end
        
        function pos = Get_Current_Position_Microns(obj)
            flush(obj.serial_com);
            obj.serial_com.write('C', 'uint8');
            
            %Cannot use readline as the numeric byte values to be read can
            %take the value '10', which is read as a CR and terminates the
            %readline call. Must instead read the desired number of bytes
            %using read()
            res = uint8(obj.serial_com.read(13, 'uint8'));
            data = typecast(res(2:end), 'uint32');
            if isempty(data)
                flush(obj.serial_com);
                obj.serial_com.write('C', 'uint8');
                res = uint8(obj.serial_com.read(13, 'uint8'));
                data = typecast(res(2:end), 'uint32');
            end
            pos.x = double(data(1)) * obj.microstep_size;
            pos.y = double(data(2)) * obj.microstep_size;
            pos.z = double(data(3)) * obj.microstep_size;
        end
    end
end
