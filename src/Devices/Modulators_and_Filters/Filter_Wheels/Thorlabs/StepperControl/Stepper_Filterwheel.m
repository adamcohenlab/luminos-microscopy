% Use Stepper_Tcube to control a filter wheel, specifically made for
% Firefly. No absolute calibration, should implement later. - DI 7/24

classdef Stepper_Filterwheel < Filter_Wheel
    properties (Transient)
        serialnumber
        stepper_motor
        bias = 14/1100; % Rotating forward and backward doesn't return to the exact same position. One loop precession = 14 motor units for 1100 back and forth's. -DI 2/25
        rot_count = [0, 0]; % Count how many times the motor has been moved back and forth.
    end

    methods
        function obj = Stepper_Filterwheel(Initializer)
            obj@Filter_Wheel(Initializer);
            obj.serialnumber = obj.Initializer.serialnumber;
            obj.stepper_motor = Stepper_TCube([], 'serialnumber',  obj.serialnumber, 'start_position', 0);
            obj.stepper_motor.moverel_deviceunit(1);
        end

        % Set filter by index. 
        function Set(obj, value)
            motor_positions = [0, 2.8, 5.6, 8.4, 11.2]; % Manually calibrated for FF. Probably move to initializer if adding another one of these.
            index = find(obj.filterlist == value);
            obj.stepper_motor.moveto(motor_positions(index));
            disp(value);
        end

       function Set_corrected(obj, value)
            motor_positions = [0, 2.8, 5.6, 8.4, 11.2];
            index = find(obj.filterlist == value);
            target = motor_positions(index) - min(obj.rot_count)*obj.bias;
            filter_index = Get(obj);
            if index < filter_index
                obj.rot_count(1) = obj.rot_count(1) + filter_index - index;
            else
                obj.rot_count(2) = obj.rot_count(2) - filter_index + index;
            end
            obj.stepper_motor.moveto(target);
            disp(target);
            disp(obj.rot_count);
            disp(value);
        end
%         function Set(obj, value)
%             motor_positions = [11.2, 0, 2.8, 5.6, 8.4]; % Manually calibrated for FF. Move to initializer if adding another one of these.
%             index = find(obj.filterlist == value);
%             target_position = motor_positions(index);
%             
%             % Get the current position of the stepper motor
%             current_position = obj.stepper_motor.position;
%             
%             % Calculate the shortest path around the wheel
%             circumference = 14;
%             positive_move = mod(target_position - current_position, circumference);
%             negative_move = mod(current_position - target_position, circumference);
%             
%             if positive_move <= negative_move
%                 final_position = mod(current_position + positive_move, circumference);
%             else
%                 final_position = mod(current_position - negative_move, circumference);
%             end
%             
%             obj.stepper_motor.moveto(final_position);
%             disp(value);
%         end

        % Return current filter index.
        function filter_index = Get(obj)
              %filter_index = find(obj.filterlist == obj.active_filter);
              %obj.active_filter
              try
                  motor_positions = [11.2, 0, 2.8, 5.6, 8.4];
                  [~, filter_index] = min(mod(abs(motor_positions - obj.stepper_motor.position),14));
              catch 
                  filter_index = 1;
              end
        end

        function delete(obj)
            obj.stepper_motor.disconnect();
        end
    end
end



