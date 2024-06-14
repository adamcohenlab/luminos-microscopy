classdef Meadowlark_PCIe_SLM_Standard < Meadowlark_SLM_Device
    properties
    end
    methods
        function obj = Meadowlark_PCIe_SLM_Standard(Initializer)
            obj@Meadowlark_SLM_Device(Initializer);
            obj.Initialize_SDK();
        end
        function delete(obj)
            if libisloaded('Blink_C_wrapper')
                obj.ClearSDK();
            end
        end
        function Project(obj, Z_SUM)
            Z_TOTAL = 256 * (Z_SUM + pi) / (2 * pi);
            final_image = uint8(mod(Z_TOTAL, 256));
            if obj.debug_mode == 0
                calllib('Blink_C_wrapper', 'Write_image', 1, final_image', 1920*1152, 0, 0, 0, 5000);
                display('Projection Command Sent!')
            else
                imagesc(obj.demo_ax(1), final_image);
                colormap(obj.demo_ax(1), 'gray');
                imagesc(obj.demo_ax(3), imwarp(obj.Target_Est, invert(obj.tform), 'OutputView', imref2d([2048, 2048])));
                colormap(obj.demo_ax(3), 'jet');
            end
        end
        function Initialize_SDK(obj)
            if ~libisloaded('Blink_C_wrapper')
                loadlibrary('C:\Program Files\Meadowlark Optics\Blink OverDrive Plus\SDK\Blink_C_wrapper.dll', 'C:\Program Files\Meadowlark Optics\Blink OverDrive Plus\SDK\Blink_C_wrapper.h');
            end
            bit_depth = 12;
            num_boards_found = libpointer('uint32Ptr', 0);
            constructed_okay = libpointer('int32Ptr', 0);
            is_nematic_type = 1;
            RAM_write_enable = 1;
            use_GPU = 0;
            max_transients = 10;
            wait_For_Trigger = 0; % This feature is user-settable; use 1 for 'on' or 0 for 'off'
            external_Pulse = 0;
            timeout_ms = 5000;
            reg_lut = libpointer('string');

            calllib('Blink_C_wrapper', 'Create_SDK', bit_depth, num_boards_found, constructed_okay, is_nematic_type, RAM_write_enable, use_GPU, max_transients, reg_lut);
            if constructed_okay.value ~= 0  
                disp('Blink SDK was not successfully constructed-1');
                disp(calllib('Blink_C_wrapper', 'Get_last_error_message'));
                calllib('Blink_C_wrapper', 'Delete_SDK');
                return;
            end
            board_number = 1;
            % load a LUT
            calllib('Blink_C_wrapper', 'Load_LUT_file', board_number, char(obj.lut_file));
            err = calllib('Blink_C_wrapper', 'Get_last_error_message');
            if ~contains(err, "No error")
                disp(err);
                calllib('Blink_C_wrapper', 'Delete_SDK');
                return
            end
            obj.Dimensions = [1920, 1152];
            obj.Target = zeros(obj.Dimensions);
            obj.calpoints = ceil(obj.Dimensions.*obj.frac_calpoints);
            if constructed_okay.value ~= 0 % Convention follows that of C function return values: 0 is success, nonzero integer is an error
                disp('Blink SDK was not successfully constructed');
                % obj.SDK_Loaded = true;
            else
                disp('Blink SDK successfully constructed');
                if ~isempty(obj.Initializer.Coverglass_Voltage)
                    obj.Coverglass_Voltage = obj.Initializer.Coverglass_Voltage;
                end
                disp('SLM Ready');
            end
        end
    end
    methods (Static)
        function ClearSDK()
            calllib('Blink_C_wrapper', 'Delete_SDK');
            unloadlibrary('Blink_C_wrapper');
        end
    end

end
