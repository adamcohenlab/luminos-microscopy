classdef Meadowlark_HDMI_SLM < Meadowlark_SLM_Device
    properties (Transient)
        SDK_Filepath
    end

    methods
        function obj = Meadowlark_HDMI_SLM(Initializer)
            obj@Meadowlark_SLM_Device(Initializer);
            obj.Initialize_SDK();
        end

        function Initialize_SDK(obj)
            if obj.Initializer.debug_mode==0
                % Ensure that preferences.ini file is correctly
                % configured for SDK.
                xx=IniConfig();
                xx.ReadFile('C:\Program Files\Meadowlark Optics\Blink 1920 HDMI\Preferences.ini');
                xx.SetValues('Global','COM Port','COM16');
                xx.WriteFile('C:\Program Files\Meadowlark Optics\Blink 1920 HDMI\Preferences.ini');
                obj.SDK_Filepath='C:\Program Files\Meadowlark Optics\Blink 1920 HDMI\SDK';
                if ~libisloaded('Blink_C_wrapper')
                    loadlibrary(fullfile(obj.SDK_Filepath,'Blink_C_wrapper.dll'), fullfile(obj.SDK_Filepath,'Blink_C_wrapper.h'));
                    %disp('Meadowlark HDIM Library Loaded');
                else
                    %disp('Blink_C_wrapper library already loaded. No need to reload');
                end
                bCppOrPython = false;
                calllib('Blink_C_wrapper','Create_SDK',bCppOrPython);
                %disp('Blink SDK was successfully constructed')
                calllib('Blink_C_wrapper', 'Load_lut', char(obj.lut_file));
                obj.Coverglass_Voltage=obj.Initializer.Coverglass_Voltage;
                %disp('SLM Ready to go')
                obj.SDK_Loaded=true;
            end
            obj.Dimensions=[1920 1152]; %Is this correct? Shouldn't it be [1152,1920]?
            obj.Target=zeros(obj.Dimensions);
            obj.calpoints=ceil(obj.Dimensions.*obj.frac_calpoints);
        end

        function Project(obj,Z_SUM)
               Z_TOTAL = 256*(Z_SUM+pi)/(2*pi);
               final_image = uint8(mod(Z_TOTAL,256));
            if obj.debug_mode==0
               calllib('Blink_C_wrapper', 'Write_image', final_image', 1);
               disp('Projection Command Sent!')
               disp(size(final_image))
            else
                imagesc(obj.demo_ax(1), final_image);
                colormap(obj.demo_ax(1), 'gray');
                imagesc(obj.demo_ax(3), imwarp(obj.Target_Est, invert(obj.tform), 'OutputView', imref2d([2048, 2048])));
                colormap(obj.demo_ax(3), 'jet');
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
