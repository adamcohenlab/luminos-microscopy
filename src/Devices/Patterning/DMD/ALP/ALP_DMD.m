% This is for ALP versions 4.2 and above.

classdef ALP_DMD < DMD
    
    properties (Transient)
        %Device Characteristics
        api_version string
        api
        device
        width
        height
        %Transform Calibration Information
        trigger DQ_DO_Finite; %DAQ or other I/O Device Channel.
        seq %Moved to transient by HD to prevent data loading issues.
        shapes = [];
    end
    
    methods
        function obj = ALP_DMD(Initializer) %
            obj@DMD(Initializer);
            obj.api_version = Initializer.api_version;
            if obj.debug_mode == 0
                [obj.api, obj.device] = init_dmd(char(obj.api_version));
                width = obj.device.width;
                height = obj.device.height;
                obj.Target = zeros(height, width);
                obj.Dimensions(1) = width;
                obj.Dimensions(2) = height;
                obj.calpoints = ceil(obj.Dimensions.*obj.frac_calpoints);
            else
                obj.Dimensions(1) = 1920;
                obj.Dimensions(2) = 1152;
                obj.calpoints = ceil(obj.Dimensions.*obj.frac_calpoints);
            end
        end
        
        function obj = dmdStopSeq(obj, seq)
            obj.device.stop;
            obj.device.halt;
            seq.free;
        end
        
        function Write_Video(obj)
            imgs = permute(obj.video_stack, [3, 1, 2]);
            obj.device.stop;
            obj.device.halt;
            
            obj.device.control(obj.api.VD_EDGE, obj.api.EDGE_RISING);
            
            BitPlanes = 1;
            PicOffset = 0;
            PicNum = size(imgs, 1);
            
            if ~isempty(obj.seq)
                dmdStopSeq(obj.device, obj.seq);
            end
            obj.seq = alpsequence(obj.device);
            obj.seq.alloc(BitPlanes, PicNum);
            obj.seq.control(obj.api.BIN_MODE, obj.api.BIN_UNINTERRUPTED); % to display the pattern
            [~, IlluminateTime] = obj.api.devinquire(obj.device.deviceid, obj.api.MIN_ILLUMINATE_TIME); % [us]
            [~, PictureTime] = obj.api.devinquire(obj.device.deviceid, obj.api.MIN_PICTURE_TIME);
            obj.seq.timing(32-2, 32, obj.api.DEFAULT, obj.api.DEFAULT, 0);
            [~, PictureTime] = obj.seq.inquire(obj.api.MIN_PICTURE_TIME);
            [~, IlluminateTime] = obj.seq.inquire(obj.api.MIN_ILLUMINATE_TIME);
            obj.seq.timing(IlluminateTime, PictureTime, obj.api.DEFAULT, obj.api.DEFAULT, 0);
            obj.seq.put(PicOffset, PicNum, imgs);
            obj.device.projcontrol(obj.api.PROJ_MODE, obj.api.MASTER);
            ALP_PROJ_STEP = int32(2329); % was missing from the matlab bindings
            obj.device.projcontrol(ALP_PROJ_STEP, obj.api.EDGE_RISING)
            obj.device.startcont(obj.seq);
        end
        
        function Write_Static(obj)
            obj.Target = obj.Target > .5;
            img = logical(obj.Target);
            % add something to check the size and the type of the image?
            if obj.debug_mode == 0
                PicNum = int32(1);
                PicOffset = int32(0);
                BitPlanes = int32(1);
                if ~isempty(obj.seq)
                    dmdStopSeq(obj.device, obj.seq);
                end
                obj.seq = alpsequence(obj.device);
                obj.seq.alloc(BitPlanes, PicNum);
                
                %obj.seq.control(obj.api.DATA_FORMAT,obj.api.DATA_BINARY_TOPDOWN);
                obj.seq.control(obj.api.BIN_MODE, obj.api.BIN_UNINTERRUPTED);
                obj.seq.timing(10E6-2E-6, 10E6, 0, 0, 0);
                obj.seq.put(PicOffset, PicNum, img');
                
                obj.device.projcontrol(obj.api.PROJ_MODE, obj.api.MASTER);
                obj.device.startcont(obj.seq);
            else
                imagesc(obj.demo_ax(1), double(img));
                Rfixed = imref2d([2048, 2048]);
                imagesc(obj.demo_ax(2), imwarp(double(img), invert(obj.tform), 'OutputView', Rfixed));
            end
        end
        
        function Write_Stack(obj, varargin)
            % Default mode is 'master'
            mode = 'master';
            
            if ~isempty(varargin)
                modeInput = varargin{1};
                if ischar(modeInput)
                    if strcmpi(modeInput, 'master')
                        %disp('Setting mode to "master".');
                        mode = 'master';
                    elseif strcmpi(modeInput, 'slave')
                        %disp('Setting mode to "slave".');
                        mode = 'slave';
                    else
                        %disp('Invalid input. Setting mode to "master" by default.');
                        mode = 'master';
                    end
                else
                    disp('Invalid input. Setting mode to "master" by default.');
                    mode = 'master';
                end
            end
            
            imgs = permute(obj.pattern_stack, [3, 2, 1]);
            imgs = imgs > .5;
            PicNum = size(imgs, 1);
            PicOffset = int32(0);
            BitPlanes = int32(1);
            obj.device.control(obj.api.VD_EDGE, obj.api.EDGE_RISING);
            
            % does this stop work?
            if ~isempty(obj.seq)
                dmdStopSeq(obj.device, obj.seq);
            end
            obj.seq = alpsequence(obj.device);
            obj.seq.alloc(BitPlanes, PicNum);
            obj.seq.control(obj.api.BIN_MODE, obj.api.BIN_UNINTERRUPTED); % to display the pattern
            [~, IlluminateTime] = obj.api.devinquire(obj.device.deviceid, obj.api.MIN_ILLUMINATE_TIME); % [us]
            [~, PictureTime] = obj.api.devinquire(obj.device.deviceid, obj.api.MIN_PICTURE_TIME);
            obj.seq.timing(32-2, 32, obj.api.DEFAULT, obj.api.DEFAULT, 0);
            [~, PictureTime] = obj.seq.inquire(obj.api.MIN_PICTURE_TIME);
            [~, IlluminateTime] = obj.seq.inquire(obj.api.MIN_ILLUMINATE_TIME);
            obj.seq.timing(IlluminateTime, PictureTime, obj.api.DEFAULT, obj.api.DEFAULT, 0);
            obj.seq.put(PicOffset, PicNum, imgs);
            
            % Apply the selected mode
            if strcmp(mode, 'master')
                obj.device.projcontrol(obj.api.PROJ_MODE, obj.api.MASTER);
            elseif strcmp(mode, 'slave')
                obj.device.projcontrol(obj.api.PROJ_MODE, obj.api.SLAVE_VD);
            end
            
            ALP_PROJ_STEP = int32(2329); % was missing from the matlab bindings
            obj.device.projcontrol(ALP_PROJ_STEP, obj.api.EDGE_RISING);
            obj.device.startcont(obj.seq);
        end
    end
end
