classdef RAS_Slave < Device
    %Virtual RAS Device
    properties (Transient)
        debugmode
        datafolder
        SLM_cal_pattern

        SLM RAS_SLM
        Stage Sutter_Stage_Controller
        Attenuator Calibrated_HWP_Polarizer_Attenuator
        Meter Newport_84x_PE

        dq_session DAQ
        rate

        waveform
        wfm_points
        cal_cycle_count

        tcp_socket tcpclient

        Laser_PP_Sync
        PMT_Gate DQ_DO_On_Demand
        laser_gate DQ_DO_On_Demand
        laser_mod DQ_AO_On_Demand
        laser_trigger_wfm DQ_DO_Wavegen
        AI_Task DQ_AI_Finite
        AO_Task DQ_AO_Wavegen
        PD_Channel DQ_Channel
        PMT_Channel DQ_Channel
        galvo_in_channel DQ_Channel
        galvo_fb_channel DQ_Channel
        galvo_chan DQ_Channel
        trigger_counter DQ_CO_Ticks

        %        Laser Amplitude_Systems_Fiber_Laser
        OPA Mango_OPA
        wavelength

        %        remote_partner tcpip
        master_ip_address string
        master_tcpip_port double

        SLM_paramfile
        DAQ_paramfile
        DAQparams
        galvo_waveformfile
        cellgroups
        LUT_Data
        gval

        scope_ax
        data_ax
        cal_ax
        data_plt
        ready

        splined_delay
        SLM_row_V
        pup
        pdown
        Tuning_Mode
        tuning_counter

        spec_data = RAS_Spec_Data.empty;
        focal_data = RAS_Snapshot_Data.empty;
    end

    properties %Put parameters that should be saved in experiment folder here.

    end

    methods (Access = private) %%Callbacks
        obj = Spec_Callback(obj, src, evt); %Callback for spectroscopy experiment
        obj = lut_cal_callback(obj, src, chan_data);
        acq_callback(obj);
        cell_acq_callback(obj);
        cal_cycle_callback(obj);
        obj = alignment_scope_callback(obj, src, evt);
    end

    methods %% CONSTRUCTOR
        function obj = RAS_Slave(Initializer, options)
            arguments
                Initializer
                options.demo_datafile = 'C:\Users\hunte\HDData\RAS_Data\Demo_Data\RAS_Demo_Data.mat';
                options.Power_Meter_Conntected = true
                options.app = [];
                options.datafolder = '';
            end
            obj@Device(Initializer);
            obj.dq_session = options.app.dq_session;
            slaveinit_container = obj.Initializer.slave_device_inits;
            obj.debugmode = debugmode;
            obj.SLM = slaveinit_container.Construct_Devices("RAS_SLM");
            obj.waveform = obj.Initializer.waveform;
            obj.wfm_points = numel(obj.waveform);
            obj.SLM_cal_pattern = 0;

            obj.Configure_On_Demands();
            obj.Initialize_DAQ();

            obj.master_ip_address = Initializer.master_ip_address;
            obj.master_tcpip_port = Initializer.master_tcpip_port;

            if debugmode == 0
                obj.OPA = slaveinit_container.Construct_Devices("Mango_OPA");
                obj.Stage = slaveinit_container.Construct_Devices("Sutter_Stage_Controller");
                obj.Attenuator = slaveinit_container.Construct_Devices("Calibrated_HWP_Polarizer_Attenuator");
            end
            obj.Set_Wave_Pow(780, .05);
        end

        function Connect_Power_Meter(obj)
            obj.Meter = obj.Initializer.slave_device_inits.Construct_Devices("Newport_84x_PE");
        end

        function Respond_to_Master_Command(obj, src, evt)

        end

        function Connect_to_Master(obj)
            obj.tcp_socket = tcp_client(master_ip_address, port);
            obj.SLM.tcp_socket = obj.tcp_socket;
        end

        function Acquire_Trace(obj, cycles)
            if obj.debugmode == 0
                obj.AI_Task.complete = false;
                obj.laser_gate.OD_Write(0);
                if ~isempty(obj.AI_Task.taskHandle)
                    obj.AI_Task.ClearTask();
                end
                obj.AI_Task.numsamples = cycles * numel(obj.galvo_chan.data);
                obj.AI_Task.Configure_Task();
                pause(5)
                obj.laser_gate.OD_Write(1);
                obj.AI_Task.Start();
                while ~obj.AI_Task.complete()
                    pause(1);
                end
                obj.acq_callback();
            else
                pause(1);
                obj.acq_callback();
            end
        end

        function prepare_laser_trigger_waveform(obj)
            triggerwaveform = [prepoints, sum(obj.SLM.Target, 2) > 0', postpoints];
            obj.laser_trigger_wfm = DQ_DO_Wavegen(triggerwaveform, obj.DAQparams.laser_trigger_channel, 500e3);
        end

        function Set_Laser_Gate(obj, state)
            if obj.debugmode == 0
                obj.laser_gate.OD_Write(state);
            else
                Display('Laser Gate Set to:');
                Display(state);
            end
        end

    end

    methods %EXPERIMENTAL ROUTINES
        Run_Spec_Routine(obj, low_nm, high_nm, power);
        Calibrate_Focal_Plane(obj, low_nm, high_nm, z_guess, halfrange, numsteps);
    end

    methods %Galvos
        function Tune_Galvo(obj, K, wfm_points)
            cycle_count = 1;
            tgt_v = mean([obj.SLM_row_V(1:512); obj.SLM_row_V(1024:-1:513)], 1);
            Vdiff = mean(diff(obj.SLM_row_V(1:512)));
            samp_delay = mean(obj.SLM_row_V(1:512)-obj.SLM_row_V(1024:-1:513)) / Vdiff;
            SLM_numrows = 512;
            padpoints = round((wfm_points - (SLM_numrows * 4))/4);
            pk_d = Vdiff * padpoints / 2;
            target_indices = [1, padpoints + (2:2:1024), (2 * padpoints + 1024), (2 * padpoints + 1025), (3 * padpoints + 1024) + (2:2:1024), 4 * padpoints + 2048];
            target_wfm_points = [min(tgt_v) - pk_d, tgt_v(1:512), max(tgt_v) + pk_d, max(tgt_v) + pk_d, tgt_v(512:-1:1), min(tgt_v) - pk_d];
            wfm_points = max(target_indices);
            tiled_indices = [target_indices, target_indices + wfm_points, target_indices + 2 * wfm_points];
            tiled_points = [target_wfm_points, target_wfm_points, target_wfm_points];
            tgt_wfm_data = spline(tiled_indices, tiled_points, wfm_points+1:2*wfm_points);
            if obj.debugmode == 0
                obj.Update_Waveform(tgt_wfm_data);
                obj.Acquisition_Mode();
                pause(1);
                obj.AO_Task.Start();
                pause(2) %Allow the galvos to reach equilibrium.
                obj.AI_Task.Start();
                while obj.AI_Task.complete == false
                    pause(.1);
                end
            end
            if obj.debugmode == 0
                tiled_galvo_command_data = repmat(obj.galvo_chan.data, [1, 10]);
                feedback_data = obj.galvo_fb_channel.data;
            else
                tiled_galvo_command_data = obj.galvo_chan.data(1:1e5);
                feedback_data = obj.galvo_fb_channel.data(1:1e5);
            end
            spline_in = spline(1:numel(tiled_galvo_command_data), tiled_galvo_command_data, 1:.01:numel(tiled_galvo_command_data));
            spline_fb = spline(1:numel(feedback_data), feedback_data, 1:.01:numel(feedback_data));
            obj.splined_delay = finddelay(spline_in, spline_fb);
            splined_tiled_target = makima(tiled_indices, tiled_points, 1:.01:wfm_points*3);
            splined_target = splined_tiled_target((wfm_points * 100 + 1):(wfm_points * 200));
            target_store = splined_target(1:100:end);
            updated_drive_splined = circshift(splined_target, -obj.splined_delay);
            updated_drive = updated_drive_splined(1:100:end);
            obj.galvo_chan.data = updated_drive;
            obj.Update_Waveform_Viewer();
            obj.tuning_counter = obj.tuning_counter + 1;
        end

        function Find_SLM_Rows(obj)
            obj.tuning_counter = 0;
            obj.Tuning_Mode = false;
            obj.SLM_cal_pattern = mod(obj.SLM_cal_pattern, 2) + 1;
            obj.SLM.Calibration_Display('offset', obj.SLM_cal_pattern-1);
            if obj.debugmode == 0
                %                obj.laser_gate.OD_Write(0);
                pause(1);
                if ~isempty(obj.AI_Task.taskHandle)
                    obj.AI_Task.ResetTask();
                end
                %obj.AI_Task.trigger_source='/Dev2/PFI1';
                obj.AI_Task.clock_source = '/Dev2/PFI0';
                obj.AI_Task.numsamples = 1000 * numel(obj.waveform);
                obj.AI_Task.Configure_Task();
                obj.AI_Task.Start();
                while ~obj.AI_Task.complete
                    pause(.2)
                end
                obj.cal_cycle_callback();
            else
                pause(1)
                obj.cal_cycle_callback();
            end
        end

        function Write_to_WFM(obj)
            uplocs = obj.pup.xpks(~isnan(obj.pup.xpks));
            downlocs = obj.pdown.xpks(~isnan(obj.pdown.xpks));

            if numel(obj.SLM_row_V) == 512
                if obj.debugmode == 1 %simulate the shift from the chaned SLM pattern
                    uplocs = uplocs + 8.5e-3;
                    downlocs = downlocs + 8.5e-3;
                end
                obj.SLM_row_V = [sort([uplocs, obj.SLM_row_V(1:256)]), sort([downlocs, obj.SLM_row_V(257:end)], 'descend')];
            else
                obj.SLM_row_V = [uplocs, downlocs(end:-1:1)];
            end
        end

        function Update_Waveform_Viewer(obj)
            plot(obj.cal_ax(3), obj.galvo_chan.data)
        end
        function SLM_X_Pattern(obj)
            obj.SLM.DisplayX();
        end

        function SLM_Alternating(obj, width, freq)
            obj.SLM.Calibration_Display('width', width, 'freq', freq);
        end

    end


    methods %Configuration Methods
        Initialize_DAQ(obj); %Defined in separate file to increase readability

        function Reconfigure_Timing(obj)
            obj.trigger_counter.ClearTask();
            obj.trigger_counter.lowticks = round(numel(obj.galvo_chan.data)/2);
            obj.trigger_counter.trigger_source = '/Dev2/PFI1';
            obj.trigger_counter.tickinput_chan = '/Dev2/PFI0';
            %obj.trigger_counter.delay=round(numel(obj.galvo_chan.data)/2);
            obj.trigger_counter.highticks = numel(obj.galvo_chan.data) - obj.trigger_counter.lowticks;
            obj.trigger_counter.Configure_Channels();
            obj.trigger_counter.Start();
            obj.dq_session.numsamples = numel(obj.galvo_chan.data);
        end

        function Configure_On_Demands(obj)
            laser_gate_channel = 'Dev2/port1/line2';
            pmt_gate_channel = 'Dev2/port1/line3';
            obj.PMT_Gate = DQ_DO_On_Demand(0, pmt_gate_channel);
            obj.PMT_Gate.name = 'PMT Gate';
            obj.laser_gate = DQ_DO_On_Demand(0, laser_gate_channel);
            obj.laser_gate.name = 'Laser Gate';
        end

        function Update_Waveform(obj, data)
            obj.laser_gate.OD_Write(0);
            obj.OPA.Set_Main_Shutter(0);
            obj.galvo_chan.data = data;
            if ~(numel(data) == obj.AO_Task.numsamples)
                obj.AO_Task.numsamples = numel(data);
                obj.trigger_counter.highticks = numel(data) / 2;
                obj.trigger_counter.lowticks = numel(data) - obj.trigger_counter.highticks;
                obj.trigger_counter.ClearTask();
                obj.trigger_counter.Configure_Channels();
                obj.trigger_counter.Start();
            end
            obj.AO_Task.ClearTask();
            obj.AO_Task.Configure_Task();
            obj.AO_Task.Start();
        end
        function Alignment_Mode(obj)
            obj.SLM.Calibration_Display('width', 2);
            if obj.debugmode == 0
                %              obj.laser_gate.OD_Write(0);
                pause(.1);
                obj.trigger_counter.ClearTask();
                obj.AO_Task.ClearTask();
                obj.AO_Task.clock_source = ' ';
                obj.AO_Task.rate = 1e5;
                obj.AO_Task.trigger_source = '';
                obj.AO_Task.Configure_Task();
                obj.trigger_counter.tickinput_chan = '/Dev2/ao/SampleClock';
                obj.trigger_counter.trigger_source = '/Dev2/ao/StartTrigger';
                obj.trigger_counter.Configure_Channels();
                obj.trigger_counter.Start();
                pause(.5)
                obj.AO_Task.Start();
            end
        end
        function Calibration_Mode(obj)
            %         obj.OPA.Set_Main_Shutter(0);
            if obj.debugmode == 0
                obj.laser_gate.OD_Write(0);
                pause(.1);
                obj.AO_Task.ResetTask();
                obj.AI_Task.ResetTask();
                obj.trigger_counter.ResetTask();
                obj.AO_Task.clock_source = ' ';
                obj.AO_Task.rate = 1e6;
                obj.AO_Task.trigger_source = '/Dev2/ctr0InternalOutput';
                obj.AO_Task.Configure_Task();
                obj.trigger_counter.tickinput_chan = '/Dev2/PFI0';
                obj.trigger_counter.trigger_source = '/Dev2/PFI1';
                obj.AI_Task.trigger_source = '/Dev2/ctr0InternalOutput';
                obj.AI_Task.clock_source = '/Dev2/PFI0';
                obj.trigger_counter.Configure_Channels();
                obj.trigger_counter.Start();
                obj.AO_Task.Configure_Task();
                pause(.5);
                obj.AO_Task.Start();
            end
        end
        function Acquisition_Mode(obj)
            obj.OPA.Set_Main_Shutter(0);
            obj.SLM.Calibration_Display('width', 2);
            if obj.debugmode == 0
                obj.laser_gate.OD_Write(0);
                pause(.1);
                obj.AO_Task.ResetTask();
                obj.AI_Task.ResetTask();
                obj.trigger_counter.ResetTask();
                obj.trigger_counter.tickinput_chan = '/Dev2/PFI0';
                obj.trigger_counter.trigger_source = '/Dev2/PFI1';
                obj.AO_Task.trigger_source = '/Dev2/ctr0InternalOutput';
                obj.AI_Task.trigger_source = '/Dev2/ctr0InternalOutput';
                obj.AO_Task.clock_source = '/Dev2/PFI0';
                obj.AI_Task.clock_source = '/Dev2/PFI0';
                obj.trigger_counter.Configure_Channels();
                obj.trigger_counter.Start();
                pause(.5);
                obj.AO_Task.Configure_Task();
                obj.AO_Task.Start();
            end
        end

    end

    methods %Calibration Methods
        Gather_LUT_Cal_Data(obj, wavelength_list);
        [calstore, lambdamixed] = Calibrate_Power(obj, min_wavelength, max_wavelength);
    end
end
