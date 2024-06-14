classdef Camera < Device
    %Call get ROI Buffer from Mex.
    properties
        clock;
        hsync_rate double;
        trigger;
        vsync;
        type; %0:emulator; 1:Hamamatsu; 2:Andor; 3:Kinetix.
        virtualSensorSize;
        microns_per_pixel;
        cam_id
        rdrivemode = true; %True: use R: drive for intermediate data store. False: write directly to data dir.
        frametrigger_source = "Off";
        daqtrig_period_ms = 10; %Period requested from daq for triggered mode in ms
        daqTrigCounter = 'Dev1/Ctr3';
        
        roiJS = struct('left', 0, 'width', 0, 'top', 0, 'height', 0, 'type', "arbitrary");
        exposuretime;
        bin;
    end
    properties (Transient = true, Hidden = true)
        plt;
        plt_timer;
        contour_data;
        data_buffer;
        
    end
    properties (SetAccess = private, Hidden = true, Transient = true)
        objectHandle; % Handle to the underlying C++ class instance
        cpp_object_initialized; %Flag indicates whether objectHandle is valid cpp instance.
    end
    properties (SetObservable)
        frames_requested = 1;
    end
    properties (SetAccess = private, SetObservable)
        ROI
        acq_complete
        dropped_frames = 0;
        dropped_frames_indicator = 0; %separate property to avoid get recursion
        readout_mode = 0; %0 =
    end
    events
        dropped_frames_event
    end
    
    methods
        
        %% Constructor - Create a new C++ class instance
        function this = Camera(Initializer)
            this@Device(Initializer);
            
            this.type = this.Initializer.type;
            if isempty(this.type)
                warning("Camera type not specified in rig config file");
            end
            this.trigger = this.Initializer.trigger;
            this.clock = this.Initializer.clock;
            this.vsync = this.Initializer.vsync;
            if isempty(this.cam_id)
                this.cam_id = '\0';
            end
            if ~this.is_remote
                this.objectHandle = CAMERA_WRAPPER_MEX('new', uint16(this.type),this.cam_id);
            end
            this.cpp_object_initialized = true;
            if ~this.is_remote
                if ~this.rdrivemode
                    CAMERA_WRAPPER_MEX('RDArray',this.objectHandle,logical(this.rdrivemode));
                end
            end
            if isempty(this.virtualSensorSize)
                this.virtualSensorSize = 2048;
            end
            if isempty(this.hsync_rate)
                this.hsync_rate = 100e3;
            end
            
            % use the most up to date ROI for the JS interface
            roiJS = this.getRoiFromStream();
            this.roiJS = roiJS;
        end
        
        function set.frametrigger_source(this, val)
            if strcmp(val, "Off")
                this.Set_Readout_Mode(0);
            else
                this.Set_Readout_Mode(1);
            end
            this.frametrigger_source = val;
        end
        
        function isValid = check_Cpp_instance(this)
            if this.cpp_object_initialized
                isValid = 1;
                return
            else
                %Could change error to warning or log, in which case return
                %value is used to indicate validity.
                warning("Underlying C++ instance not valid on Camera function call");
                isValid = 0;
                return
            end
        end
        
        %% Destructor - Destroy the C++ class instance
        function delete(this)
            if this.check_Cpp_instance()
                this.cpp_object_initialized=false;
                CAMERA_WRAPPER_MEX('delete', this.objectHandle);
            end
        end
        
        function SetCmapLimits(this, low, high)
            if this.check_Cpp_instance()
                CAMERA_WRAPPER_MEX('Set_Cmap_Limits',this.objectHandle,double(low),double(high));
            end
        end
        
        function SetRDriveMode(this, mode)
            if this.check_Cpp_instance()
                this.rdrivemode=mode;
                CAMERA_WRAPPER_MEX('RDArray',this.objectHandle,logical(this.rdrivemode));
            end
        end
        
        %% Relaunch (for use in case of error)
        function Relaunch(this)
            if this.check_Cpp_instance()
                this.cpp_object_initialized=false;
                CAMERA_WRAPPER_MEX('delete',this.objectHandle);
                this.objectHandle=CAMERA_WRAPPER_MEX('new',uint16(this.type));
                this.cpp_object_initialized=true;
                if ~this.rdrivemode
                    CAMERA_WRAPPER_MEX('RDArray',this.objectHandle,logical(this.rdrivemode));
                end
                Get_ROI(this);
            end
        end
        
        %% Get_ROI_Buffer pulls all available data from the ROImean buffer,
        % which represents the mean counts over the user-selected sub-ROI
        % within the viewport
        function data = Get_ROI_Buffer(this)
            if this.check_Cpp_instance()
                data = CAMERA_WRAPPER_MEX('Get_ROI_Buffer', this.objectHandle);
            end
        end
        
        %% Get_ROI_Sum_Buffer pulls all available data from the ROI_Sum buffer,
        % which represents the total counts over the user-selected sub-ROI
        % within the viewport
        function data = Get_ROI_Sum_Buffer(this)
            % "Getting ROI Sum"
            if this.check_Cpp_instance()
                data = CAMERA_WRAPPER_MEX('Get_ROI_Sum_Buffer', this.objectHandle);
            end
        end
        
        %% Get bounds of user-selected sub-ROI within the viewport (rectangle
        % drawn within live view window).
        function res = Get_subROI(this)
            if this.check_Cpp_instance()
                res=CAMERA_WRAPPER_MEX('Get_SumRect',this.objectHandle);
            end
        end
        
        %% Snap returns a snapshot from the camera into memory. Useful for passing an image to other virtual devices.
        function frame = Snap(this)
            if this.check_Cpp_instance()
                frame = CAMERA_WRAPPER_MEX('GetSnap', this.objectHandle);
                frame = frame';
            end
        end
        
        %%
        function Prepare_Sync_Aq(this, exposuretime, ROIin, binning)
            if this.check_Cpp_instance()
                
                this.exposuretime = exposuretime;
                this.ROI = ROIin;
                this.bin = binning;
                %Don't call other things after the prepare_sync_aq mex
                %call, because they can "unprepare" the camera.
                CAMERA_WRAPPER_MEX('Prepare_Sync_Aq', this.objectHandle, exposuretime, int32(ROIin), uint32(binning));
            end
        end
        
        function dropped_frames = get.dropped_frames(this)
            dropped_frames = this.Dropped_Frames_Check();
        end
        
        function dropped_frames = Dropped_Frames_Check(this)
            if this.check_Cpp_instance()
                dropped_frames=CAMERA_WRAPPER_MEX('Check_Dropped_Frames', this.objectHandle);
                if isempty(dropped_frames)
                    this.dropped_frames = 0;
                else
                    this.dropped_frames_indicator = dropped_frames; %For indicator light on panel.
                    this.dropped_frames = dropped_frames; %If AbortSet property, then setting results in get call
                    if dropped_frames > 0
                        warning('DROPPED FRAMES DETECTED IN LAST ACQUISITION!');
                    end
                end
            end
        end
        
        function acq_complete = get.acq_complete(this)
            if this.check_Cpp_instance()
                acq_complete=CAMERA_WRAPPER_MEX('Check_Acq_Done', this.objectHandle);
                %acq_complete=true;
                this.acq_complete = acq_complete;
            end
        end
        
        function setBinningInCpp(this, binning)
            if this.check_Cpp_instance()
                if(binning==1 || binning==2 || binning==4)
                    CAMERA_WRAPPER_MEX('Set_Binning', this.objectHandle,uint32(binning));
                else
                    warning('Illegal binning value: Allowed values are 1,2,and 4')
                end
            end
        end

        function set.bin(this,binning)
            this.setBinningInCpp(binning);
        end

        function binning = get.bin(this)
            if this.check_Cpp_instance()
                binning = CAMERA_WRAPPER_MEX('Get_Binning',this.objectHandle);
            end
        end
        
        function set.exposuretime(this, exposuretime)
            if this.check_Cpp_instance()
                % min_exposure_time = 1 / this.calculate_max_framerate();
                % if exposuretime < min_exposure_time
                %     error('Exposure time too short. Minimum allowed exposure time is %f s', min_exposure_time);
                % end
                this.setExposureTimeInCpp(exposuretime);
            end
        end
        
        function setExposureTimeInCpp(this, exposuretime)
            if this.check_Cpp_instance()
                CAMERA_WRAPPER_MEX('Set_Exposure', this.objectHandle, exposuretime);
            end
        end
        
        function exposureTime = get.exposuretime(this)
            if this.check_Cpp_instance()
                exposureTime = CAMERA_WRAPPER_MEX('Get_Exposure', this.objectHandle);
            end
        end
        
        % Get the ROI from the live camera view in a user friendly format
        function roiJS = getRoiFromStream(this)
            roi = this.Get_ROI();
            roiJS = this.roiArrayToStruct(roi, this.roiJS.type);
        end
        
        % Convert ROI from array format to a struct format
        function roiJS = roiArrayToStruct(this, roiArray, roiType)
            roiJS = struct('left', roiArray(1), 'width', roiArray(2), 'top', roiArray(3), 'height', roiArray(4), 'type', roiType);
        end
        
        % Convert ROI from struct format to an array format
        function roiArray = roiStructToArray(this, roiStruct)
            roiArray = [roiStruct.left, roiStruct.width, roiStruct.top, roiStruct.height];
        end
        
        % Get the ROI from the JS interface in array format
        function roi = getROIForAcquisition(this)
            roi = this.roiStructToArray(this.roiJS);
        end
        
        % Set the ROI in a user friendly format. This function gets called from the JS
        function set.roiJS(this, roiJS)
            roiToSet = this.setCameraROI(roiJS, roiJS.type);
            this.roiJS = this.roiArrayToStruct(roiToSet, roiJS.type);
        end
        
        function roiToSet = setCameraROI(this, ROI_JS, type)
            % arbitrary rectangular region
            if type == "arbitrary"
                roiToSet = [ROI_JS.left, ROI_JS.width, ROI_JS.top, ROI_JS.height];
                
                % centered region
            elseif type == "centered" % Pre-formats the ROI for high-speed acquisition
                % round so it's compatible with the camera
                width = min(max(ceil(ROI_JS.width/8)*8, 8), this.virtualSensorSize);
                height = min(max(ceil(ROI_JS.height/8)*8, 8), this.virtualSensorSize);
                
                % compute the top left corner of the ROI
                top = (this.virtualSensorSize - ROI_JS.height) / 2;
                left = (this.virtualSensorSize - ROI_JS.width) / 2;
                roiToSet = [left, width, top, height];
            end
            roiToSet = this.Set_ROI(int32(roiToSet));
            this.Set_ROI(roiToSet);
        end
        
        %Set the camera recording ROI (portion of FOV captured by camera).
        function res = Set_ROI(this, ROIin)
            if this.check_Cpp_instance()
                res=CAMERA_WRAPPER_MEX('Set_ROI',this.objectHandle,ROIin);
                this.ROI=res;
            end
        end
        
        %Choose between camera operation modes ('readout' mode is probably
        %a misnomer since that properly (at least on Hamamatsu) would
        %refer to light sheet vs normal area readout).
        %0: External edge start-trigger mode (camera starts acquiring set
        %number of frames at set exposure upon receiving initial trigger
        %edge).
        %1: External Synchronous-triggered mode (camera acquires one frame
        %for each external trigger pulse sent to camera. On Hamamatsu, each
        %frame ends when the next trigger arrives).
        function Set_Readout_Mode(this,mode)
            CAMERA_WRAPPER_MEX('Set_Read_Mode',this.objectHandle,int32(mode));
            this.readout_mode=mode;
        end
        
        %Get the camera recording ROI bounds (portion of FOV captured by
        %camera).
        function res = Get_ROI(this)
            if this.check_Cpp_instance()
                res=CAMERA_WRAPPER_MEX('Get_ROI',this.objectHandle);
                this.ROI=res;
            end
        end
        
        function Start_Acquisition(this, numFrames, fpath)
            if this.check_Cpp_instance()
                this.frames_requested = numFrames;
                modpath = fullfile(fpath); %standardize file formatting
                fprintf("Saving to %s\n", modpath);
                modpath = strrep(modpath, '\', '\\');
                CAMERA_WRAPPER_MEX('Start_Acquisition', this.objectHandle,uint32(numFrames),char(modpath));
                notify(this,'exp_finished'); %This is a bit silly since we notify the app that we're done
                % without actually finishing first. Is there a better way?
                % This can cause confusing errors.
            end
        end
        
        function res = Is_Cam_Recording(this)
            if this.check_Cpp_instance()
                res=CAMERA_WRAPPER_MEX('Is_Cam_Recording', this.objectHandle);
            end
        end
        
        function Wait_Until_Done(this)
            while this.acq_complete == 0
                pause(.1);
            end
        end
        
        function framerate = calculate_framerate(obj)
            %Right now only implements Hamamatsu Flash formulas for Camera
            %Link configuration. Will be different using USB3 or a
            %different type of camera.
            
            % Hunter's Note: These calculations do not work for the Fusion
            % Camera. They will be updated in a future commit.
            expos = obj.exposuretime;
            switch obj.type
                case 1 %Hamamatsu
                    
                    H = 9.74436e-6; %constant from camera manual
                    roi = double(obj.Get_ROI());
                    side1 = obj.virtualSensorSize/2-roi(3);
                    max_lines_from_center = max(side1,roi(4)-side1);
                    mode = obj.readout_mode;
                    switch mode
                        case 0 %internal or free-running mode (or start trigger mode)
                            framerate = min(1/(max_lines_from_center * H), 1/expos);
                        case 1 %Synchronous readout trigger mode (Frame lasts until next trigger arrives)
                            warning("Calculation only valid if exposure field is set to period between triggers. May not be actual rate");
                            framerate = min(1/expos, 1/(max_lines_from_center * H + H * 17));
                        case 2 %Externally trigger each frame, with software defined exposure time
                            warning("Framerate depends on trigger waveform sent to camera. May not be actual rate");
                            framerate = min(1/expos, 1/(max_lines_from_center * H + expos + H * 9));
                    end
                otherwise
                    warning("Auto N only works for Hamamatsu PCIe camera interface at the moment. Please add correct algorithms for your camera to the calculate_framerate method of the Camera_Controller class.");
                    framerate = 1 / obj.exposuretime;
            end
        end
        
        function N = AutoN(obj, total_time)
            %Use the total acquisition time from the waveform tab along
            %with the camera acquisition parameters to automatically
            %calculate the proper number of frames to take such that the
            %camera does not stop until the DAQ has.
            
            framerate = obj.calculate_framerate();
            N = ceil(total_time*framerate);
            obj.frames_requested = N;
        end
        
        %Calculate and return maximum framerate given current ROI and
        %acquisition mode
        function framerate = calculate_max_framerate(obj)
            %Right now only implements Hamamatsu Flash formulas for Camera
            %Link configuration. Will be different using USB3 or a
            %different type of camera.
            
            % Hunter's Note: These calculations do not work for the Fusion
            % Camera. They will be updated in a future commit.
            switch obj.type
                case 1 %Hamamatsu
                    expos = (obj.exposuretime);
                    H = 9.74436e-6; %constant from camera manual
                    roi = double(obj.Get_ROI());
                    side1 = obj.virtualSensorSize/2-roi(3);
                    max_lines_from_center = max(side1,roi(4)-side1);
                    mode = obj.readout_mode;
                    switch mode
                        case 0 %internal or free-running mode (or start trigger mode)
                            framerate = 1 / (max_lines_from_center * H);
                        case 1 %Synchronous readout trigger mode (Frame lasts until next trigger arrives)
                            framerate = 1 / (max_lines_from_center * H + H * 17);
                        case 2 %Externally trigger each frame, with software defined exposure time
                            framerate = 1 / (max_lines_from_center * H + expos + H * 9);
                    end
                otherwise
                    warning("Maximum framerate calculation not defined for your camera type/config. Please update the calculate_max_framerate method in the Camera class.");
                    framerate = Inf;
            end
        end
    end
end
