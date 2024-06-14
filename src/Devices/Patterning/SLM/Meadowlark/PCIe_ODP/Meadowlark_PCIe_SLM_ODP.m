classdef Meadowlark_PCIe_SLM_ODP < Meadowlark_SLM_Device
    properties (Transient)
        sdk
    end

    methods
        function obj = Meadowlark_PCIe_SLM_ODP(Initializer)
            obj@Meadowlark_SLM_Device(Initializer);
            obj.Initialize_SDK();
        end
        function delete(obj)
            calllib('Blink_SDK_C', 'SLM_power', obj.sdk, 0); %Turn the SLM off
            calllib('Blink_SDK_C', 'Delete_SDK', obj.sdk);
            if libisloaded('Blink_SDK_C')
                unloadlibrary('Blink_SDK_C');
            end
        end
        function Project(obj, Z_TOTAL)
            final_image = uint8(mod(Z_TOTAL, 256));
            if obj.debug_mode == 0
                calllib('Blink_SDK_C', 'Write_image', obj.sdk, 1, final_image', 512, 0, 0, 5000);
            else
                imagesc(obj.demo_ax(1), final_image);
                colormap(obj.demo_ax(1), 'gray');
                %imagesc(obj.demo_ax(3),imwarp(obj.Target_Est,invert(obj.tform),'OutputView',imref2d([2048 2048])));
                %colormap(obj.demo_ax(3),'jet');
            end
        end
        function Initialize_SDK(obj)
            if ~libisloaded('Blink_SDK_C')
                filepath = fileparts(mfilename('fullpath'));
                loadlibrary([filepath, '\SDK\Blink_SDK_C.dll'], [filepath, '\SDK\Blink_SDK_C_wrapper.h']);
            end
            % Basic parameters for calling Create_SDK
            bit_depth = 8; %For the 512L bit depth is 16, for the small 512 bit depth is 8
            num_boards_found = libpointer('uint32Ptr', 0);
            constructed_okay = libpointer('int32Ptr', 0);
            is_nematic_type = 1;
            RAM_write_enable = 1;
            use_GPU = 0;
            max_transients = 10;
            wait_For_Trigger = 0;
            external_Pulse = 0;
            timeout_ms = 5000;
            lut_file = obj.lut_file;
            reg_lut = libpointer('string');

            % Basic SLM parameters
            true_frames = 3;

            obj.sdk = calllib('Blink_SDK_C', 'Create_SDK', bit_depth, num_boards_found, constructed_okay, is_nematic_type, RAM_write_enable, use_GPU, max_transients, reg_lut);

            if constructed_okay.value ~= 0 % Convention follows that of C function return values: 0 is success, nonzero integer is an error
                disp('Blink SDK was not successfully constructed');
                disp(calllib('Blink_SDK_C', 'Get_last_error_message', obj.sdk));
            else
                disp('Blink SDK was successfully constructed');
                fprintf('Found %u SLM controller(s)\n', num_boards_found.value);
                % Set the basic SLM parameters
                calllib('Blink_SDK_C', 'Set_true_frames', obj.sdk, true_frames);
                % A linear LUT must be loaded to the controller for OverDrive Plus
                calllib('Blink_SDK_C', 'Load_LUT_file', obj.sdk, 1, lut_file);
                % Turn the SLM power on
                calllib('Blink_SDK_C', 'SLM_power', obj.sdk, 1);
            end
        end

    end
end
