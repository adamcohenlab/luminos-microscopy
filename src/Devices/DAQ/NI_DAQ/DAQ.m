% We assume you use an NI_DAQ

classdef DAQ < Device
    properties (Transient = true) % transient = true means these properties aren't saved on serialization
        %%Timing Properties
        rate
        trigger
        clock
        numsamples
        alias_list
        defaultClock string
        default_trigger string

        % data from the waveform ui
        global_props
        wfm_data
    end
    properties (Transient)
        counter_inputs
        trigger_output_task
        taskdone_listeners = event.listener.empty;
        savefolder
        Device_List
        AI_Ports
        AO_Ports
        DIO_Ports
        Terminals
        alias_init string
        Camtrig_Counter_Configured = false;
        Counters
        waveforms_built %flag to check whether waveforms have been built.
    end
    properties (SetObservable = true) % SetObservable = true means that changes to these properties will trigger a callback
        %%TaskContainers
        Dedicated_Camtrig_Counter;
        cfclsync_counter_configured = false;
        cfclsync_counter = DQ_CO_Ticks.empty;
        buffered_tasks = DQ_Buffered_Task.empty;
        Counter_Inputs = DQ_Edge_Count.empty;
        Counter_Outputs = DQ_CO_Ticks.empty;
        timebase;
        downsampling_counter;
        secondary_clock;
        secondary_trigger;
    end
    properties (SetObservable, Transient)
        counter_outputs = DQ_CO_Ticks.empty;
        DAQ_Master
    end
    events
        tasks_done
    end
    methods %Callbacks
        function obj = savetasks(obj, src, evt) %called on change of "complete" property in a task
            if obj.standalone_mode
                if (sum(cell2mat({obj.buffered_tasks.complete})) == numel(obj.buffered_tasks))
                    DAQ_tasks = obj.buffered_tasks;
                    save(fullfile(obj.savefolder, 'wavedata.mat'), 'DAQ_tasks', '-nocompression');
                    for i = 1:numel(obj.buffered_tasks)
                        obj.taskdone_listeners(i).Enabled = false;
                    end
                end
            else
                if ~isempty(obj.Counter_Inputs)
                    if (sum(cell2mat({obj.buffered_tasks.complete})) == numel(obj.buffered_tasks)) && obj.Counter_Inputs(1).complete == 1
                        notify(obj, 'exp_finished');
                    end
                else
                    if (sum(cell2mat({obj.buffered_tasks.complete})) == numel(obj.buffered_tasks))
                        notify(obj, 'exp_finished');
                    end
                end
            end
        end
    end

    methods
        function obj = DAQ(Initializer, options)
            arguments
                Initializer
                options.standalone_mode = false;
            end
            obj@Device(Initializer);
            % reset the daq
            daqreset;
            for i = 1:numel(obj.Device_List)
                [aa] = daq.ni.NIDAQmx.DAQmxResetDevice(obj.Device_List{i});
            end
            if ~isempty(Initializer)
                if ~(isempty(Initializer.alias_init) || strcmp(Initializer.alias_init,""))
                    obj.alias_init = Initializer.alias_init;
                    obj.alias_list = reshape(strip(strsplit(obj.alias_init, ',')), 2, [])';
                end
            end
            obj.Get_Device_information();
            obj.DAQ_Master = true;
            obj.standalone_mode = options.standalone_mode;
        end

        function Add_Scanning_Sync_Counter(obj, numsamples)
            if obj.cfclsync_counter_configured
                obj.cfclsync_counter.ResetTask();
            else
                obj.cfclsync_counter = DQ_CO_Ticks('Enabled Scanning Counter', 'Dev2/Ctr1', '/Dev2/ao/SampleClock', round(numsamples/2), numsamples-round(numsamples/2));
            end
            obj.cfclsync_counter.Configure_Channels();
            obj.cfclsync_counter.AddTrigger('/Dev2/Ctr0InternalOutput', 'rising');
            obj.cfclsync_counter_configured = true;
        end

        function Add_Dedicated_Camtrig_Counter(obj, frame_period_ms, counter, timebase_source, trigger_source, options)
            arguments
                obj
                frame_period_ms
                counter
                timebase_source
                trigger_source
                options.camera_hsync_rate_khz = 100
            end
            cnumsamples = frame_period_ms * options.camera_hsync_rate_khz;
            if obj.Camtrig_Counter_Configured
                obj.Dedicated_Camtrig_Counter.ResetTask('highticks', round(cnumsamples/2), 'lowticks', cnumsamples-round(cnumsamples/2), 'configure_now', true);
            else
                obj.Dedicated_Camtrig_Counter = DQ_CO_Ticks('Camtrig Counter', counter, timebase_source, round(cnumsamples/2), cnumsamples-round(cnumsamples/2));
                obj.Dedicated_Camtrig_Counter.Configure_Channels();
            end
            if ~isempty(trigger_source)
                obj.Dedicated_Camtrig_Counter.AddTrigger(trigger_source, 'rising');
            end
            obj.Camtrig_Counter_Configured = true;
        end

        function tvec = Calculate_tvec(obj, timing_data)
            numSamples = round(timing_data.total_time*timing_data.rate);
            tvec = linspace(0, 1/timing_data.rate*(numSamples - 1), numSamples);
        end

        function out = Calculate_Waveform(obj, timing_data, wfminfo)
            tvec = obj.Calculate_tvec(timing_data);
            params = toCell(wfminfo.params);
            out = feval(wfminfo.wavefile, tvec, params{:});
        end

        function Build_Waveforms_Type(obj, wavedata, timing_data, type)
            % wavedata: {port, name, wfminfo?,...}
            % type: "ao" or "do" or "ai"

            if isempty(wavedata)
                return
            end

            if type == "ao"
                task = obj.Add_AO_Task();
            elseif type == "do"
                task = obj.Add_DO_Task();
            elseif type == "ai"
                task = obj.Add_AI_Task();
            end

            for i = 1:numel(wavedata)
                if type == "ai"
                    data = [];
                else
                    data = obj.Calculate_Waveform(timing_data, wavedata(i));
                end

                obj.Attach_Channel_THandle(task, wavedata(i).name, ...
                    wavedata(i).port, 'data', data);
            end

        end

        function task = Build_Waveforms_Combined(obj, wavedata, timing_data, type, task)
            % wavedata: {port, name, wfminfo?,...}
            % type: "ao" or "do" or "ai"

            if isempty(wavedata)
                return
            end

            if (type == "ao") && (isempty(task))
                task = obj.Add_AO_Task();
            elseif type == "do" && (isempty(task))
                task = obj.Add_DO_Task();
            end

            data = obj.Calculate_Waveform(timing_data, wavedata(1));
            for i = 2:numel(wavedata)
                data = data.*obj.Calculate_Waveform(timing_data, wavedata(i));
            end

            obj.Attach_Channel_THandle(task, wavedata(1).name, ...
                wavedata(1).port, 'data', data);
            
        end

        % DI 2/24 additions:
        % Duplicate waveforms for the same device are multiplied together
        % instead of causing error.

        function success = Build_Waveforms(obj)
            % global_props: {total_time, rate, clock_source, trigger_source, folder}
            % wfm_data: {ao, do, ai, ctri}
            % ao/do/ai: [{port, name, wfminfo?,...}, ...]

            if isempty(obj.wfm_data.ao) && isempty(obj.wfm_data.do) && isempty(obj.wfm_data.ai)
                error('Waveforms are empty. Add waveforms before building');
            end
            delete(obj.buffered_tasks);
            obj.buffered_tasks(:) = [];
            obj.numsamples = round(obj.global_props.total_time*obj.global_props.rate);
            obj.rate = obj.global_props.rate;
            obj.clock = obj.remove_al(obj.global_props.clock_source); %device specific clock
            obj.trigger = strcat('/', obj.remove_al(obj.global_props.trigger_source)); %device specific trigger
            obj.DAQ_Master = obj.global_props.daq_master;


            % Process AO waveforms
            if (~isempty(obj.wfm_data.ao))
                ao_names = {obj.wfm_data.ao.name};
                [uniqueNames, ~, idx] = unique(ao_names);
                counts = accumarray(idx, 1);
                duplicateIdx = find(counts > 1);
    
                if isempty(duplicateIdx)
                    obj.Build_Waveforms_Type(obj.remove_aliases(obj.wfm_data.ao), obj.global_props, "ao");
                else
                    task = [];
                    for i = 1:length(uniqueNames)
                        if ismember(i, duplicateIdx)
                            % Find all occurrences of this name
                            dupIndices = find(idx == i);
                            task = obj.Build_Waveforms_Combined(obj.remove_aliases(obj.wfm_data.ao(dupIndices)), obj.global_props, "ao", task);
                        else
                            % Find the index of this unique name
                            index = find(idx == i, 1, 'first');
                            task = obj.Build_Waveforms_Combined(obj.remove_aliases(obj.wfm_data.ao(index)), obj.global_props, "ao",task);
                        end
                    end
                end
            else
                obj.Build_Waveforms_Type(obj.remove_aliases(obj.wfm_data.ao), obj.global_props, "ao");
            end

            % Process DO waveforms
            if (~isempty(obj.wfm_data.do))
                do_names = {obj.wfm_data.do.name};
                [uniqueNames, ~, idx] = unique(do_names);
                counts = accumarray(idx, 1);
                duplicateIdx = find(counts > 1);
                
                if isempty(duplicateIdx)
                    obj.Build_Waveforms_Type(obj.remove_aliases(obj.wfm_data.do), obj.global_props, "do");
                else
                    task = [];
                    for i = 1:length(uniqueNames)
                        if ismember(i, duplicateIdx)
                            % Find all occurrences of this name
                            dupIndices = find(idx == i);
                            % Assuming Build_Waveforms_Combined can handle multiple indices
                            task = obj.Build_Waveforms_Combined(obj.remove_aliases(obj.wfm_data.do(dupIndices)), obj.global_props, "do",task);
                        else
                            % Find the index of this unique name
                            index = find(idx == i, 1, 'first');
                            task = obj.Build_Waveforms_Type(obj.remove_aliases(obj.wfm_data.do(index)), obj.global_props, "do", task);
                        end
                    end
                end
            else
                obj.Build_Waveforms_Type(obj.remove_aliases(obj.wfm_data.do), obj.global_props, "do");
            end

            % Analog input don't check for duplicate tasks. Returns error
            % as it should.
            obj.Build_Waveforms_Type(obj.remove_aliases(obj.wfm_data.ai), obj.global_props, "ai");

            if ~isempty(obj.wfm_data.ctri) % counter input; used for VR rotary encoder
                wavedata = obj.wfm_data.ctri;
                roto = DQ_Edge_Count(wavedata(1).port, obj.numsamples, obj.rate, 'name', wavedata(1).name);
                obj.Counter_Inputs(1) = roto;
            end
            %di tasks currently unsupported but can be added later.

            obj.Configure_Simple_Sync_Finite();
            obj.waveforms_built = true;
            success = 1;

        end

        function port = remove_al(obj, port)
            % replace alias with its actual port name for a single port
            for j = 1:size(obj.alias_list, 1)
                if strcmp(port, obj.alias_list{j, 2})
                    port = obj.alias_list{j, 1};
                    return
                end
            end
        end

        function ports = remove_aliases(obj, ports)
            % replace aliases with their actual port names
            for i = 1:numel(ports)
                ports(i).port = obj.remove_al(ports(i).port);
            end
        end

        function Configure_Simple_Sync_Finite(obj)
            delete(obj.taskdone_listeners)
            obj.taskdone_listeners(:) = [];
            obj.Fix_Repeat_Handles();
            if strcmp(obj.clock, ' ')
                obj.Sync_Internal_Clocks(1);
            else
                for i = 1:numel(obj.buffered_tasks)
                    if ~isempty(obj.buffered_tasks(i).clock_source)
                        if strcmp(obj.buffered_tasks(i).clock_source, ' ')
                            obj.buffered_tasks(i).clock_source = obj.clock;
                        end
                    end
                end
                for i = 1:numel(obj.Counter_Inputs)
                    master_tasktype = obj.buffered_tasks(1).task_type(1:2);
                    master_device_name = obj.buffered_tasks(1).channels(1).phys_channel(1:4);
                    master_sample_clock = ['/', master_device_name, '/', master_tasktype, '/SampleClock'];
                    obj.Counter_Inputs(i).clock_source = master_sample_clock;
                end
            end
            for i = 1:numel(obj.buffered_tasks)

                %% hunter add
                if isempty(obj.buffered_tasks(i).trigger_source)
                    obj.buffered_tasks(i).trigger_source = obj.trigger;
                end

                %% end hunter add
                obj.buffered_tasks(i).Configure_Task();
                obj.taskdone_listeners(i) = addlistener(obj.buffered_tasks(i), 'complete', 'PostSet', @obj.savetasks);
                obj.taskdone_listeners(i).Enabled = false; %disable the listener in case something funny happens in external code between configuration and start
            end
            for i = 1:numel(obj.Counter_Inputs)
                obj.Counter_Inputs(i).Configure_Task();
                obj.taskdone_listeners(end+1) = addlistener(obj.Counter_Inputs(i), 'complete', 'PostSet', @obj.savetasks);
                obj.taskdone_listeners(end).Enabled = false;
            end
        end

        function Start_Tasks(obj)
            for i = 1:numel(obj.taskdone_listeners)
                obj.taskdone_listeners(i).Enabled = true;
            end
            for i = numel(obj.buffered_tasks):-1:1 %Start master last
                obj.buffered_tasks(i).Start();
            end
            for i = 1:numel(obj.Counter_Inputs)
                obj.Counter_Inputs(i).Start();
            end
            if obj.DAQ_Master %If DAQ is serving as the master trigger.
                obj.trigger_output_task = DQ_DO_On_Demand(0, obj.trigger);
                fprintf('Triggering on %s\n', obj.trigger);
                obj.trigger_output_task.OD_Write(1);
                pause(.001); %Flush to make sure the previous write completes
                obj.trigger_output_task.OD_Write(0);
            end
        end

        function Sync_Internal_Clocks(obj, master_index)
            master_tasktype = obj.buffered_tasks(master_index).task_type(1:2);
            master_device_name = obj.buffered_tasks(master_index).channels(1).phys_channel(1:4);
            master_sample_clock = ['/', master_device_name, '/', master_tasktype, '/SampleClock'];
            for i = 1:numel(obj.buffered_tasks)
                if i ~= master_index && strcmp(obj.buffered_tasks(i).clock_source, ' ') %Added additional check to hack in multi-device synchronization
                    % hunter add
                    if strcmp(obj.buffered_tasks(i).channels(1).phys_channel(1:4), master_device_name)
                        obj.buffered_tasks(i).clock_source = master_sample_clock;
                    else
                        error('Multi-Device synchronization requires explicit clock specification for worker.')
                    end
                    % end hunter add
                end
            end
            for i = 1:numel(obj.Counter_Inputs)
                obj.Counter_Inputs(i).clock_source = master_sample_clock;
            end
        end

        function Add_Secondary_Clock_Connection(obj, clkcon, triggercon)
            for i = 1:numel(obj.buffered_tasks)
                if ~isempty(obj.buffered_tasks(i).channels)
                    if contains(obj.buffered_tasks(i).channels(1).phys_channel, clkcon(1:4))
                        obj.buffered_tasks(i).clock_source = clkcon;
                        obj.buffered_tasks(i).trigger_source = triggercon;
                    end
                end
            end
        end

        function Attach_Clock2(obj)
            obj.Add_Secondary_Clock_Connection(obj.secondary_clock, obj.secondary_trigger);
        end

        function counter_out = Add_Counter_Clock(obj, source, options)
            arguments
                obj DAQ;
                source
                options.trigger = '';
                options.name = '';
                options.clk_division = 2;
                options.set_to_master_clock = true;
                options.start_delay = 0;
                options.counter = [obj.Counters(numel(obj.counter_outputs)+1).Device, '/', obj.Counters(numel(obj.counter_outputs)+1).PortID];
            end
            assert(mod(options.clk_division, 2) == 0, 'Only even division factors supported')
            obj.counter_outputs(end+1) = DQ_CO_Ticks(options.name, options.counter, source, ...
                options.clk_division/2, options.clk_division/2, 'trigger_source', options.trigger, ...
                'start_delay', options.start_delay);
            counter_out = obj.counter_outputs(end);
            if options.set_to_master_clock
                obj.clock = counter_out.counter_chan; %Need to add InternalOutput Argument?
            end
            obj.CheckHandle(counter_out);
        end

        function Create_Downsampled_Clock(obj, source, counter, input_frequency, output_frequency)
            downsample = round(input_frequency/output_frequency);
            if ~isEven(downsample) || downsample ~= input_frequency / output_frequency
                warning(['Only round and even clock division factors supported. Downsampling rounded to', ' ', num2str(downsample)])
            end
            counter = obj.Add_Counter_Clock(source, 'clk_division', downsample, 'counter', counter);
            disp(['Created Downsampled Clock. Please set the task clock to the internal output from', ' ', counter.counter_chan]);
        end

        function Downsmpl_clk(obj, input_frequency, output_frequency)
            obj.Create_Downsampled_Clock(obj.timebase, obj.downsampling_counter, input_frequency, output_frequency);
        end

        function task_out = Add_AO_Task(obj, options)
            arguments
                obj DAQ
                options.rate = obj.rate
                options.clock = obj.clock
                options.numsamples = obj.numsamples
                options.trigger_source = obj.trigger
            end
            obj.buffered_tasks(end+1) = DQ_AO_Finite(options.numsamples, options.rate, 'clock_source', options.clock, 'trigger_source', options.trigger_source);
            task_out = obj.buffered_tasks(end);
            obj.CheckHandle(task_out);
        end

        function task_out = Add_AO_Wavegen_Task(obj, options)
            arguments
                obj DAQ
                options.clock = obj.clock;
                options.rate = obj.rate;
                options.numsamples = obj.numsamples;
                options.trigger_source = obj.trigger;
            end
            obj.buffered_tasks(end+1) = DQ_AO_Wavegen(options.numsamples, options.rate, 'clock_source', options.clock, 'trigger_source', options.trigger_source);
            task_out = obj.buffered_tasks(end);
            obj.CheckHandle(task_out);
        end

        function task_out = Add_AI_Task(obj, options)
            arguments
                obj DAQ
                options.rate = obj.rate
                options.clock = obj.clock
                options.numsamples = obj.numsamples
                options.trigger_source = obj.trigger
            end
            obj.buffered_tasks(end+1) = DQ_AI_Finite(options.numsamples, options.rate, 'clock_source', options.clock, 'trigger_source', options.trigger_source);
            task_out = obj.buffered_tasks(end);
            obj.CheckHandle(task_out);
        end

        function task_out = Add_Cont_AI_Task(obj, options)
            arguments
                obj DAQ
                options.rate = obj.rate
                options.clock = obj.clock
                options.numsamples = obj.numsamples
                options.trigger_source = obj.trigger
            end
            obj.buffered_tasks(end+1) = DQ_AI_Cont(options.numsamples, options.rate, ...
                'clock_source', options.clock, 'trigger_source', options.trigger_source);
            task_out = obj.buffered_tasks(end);
        end

        function task_out = Add_DO_Task(obj, options)
            arguments
                obj DAQ
                options.rate = obj.rate
                options.clock = obj.clock
                options.numsamples = obj.numsamples
                options.trigger_source = obj.trigger
            end
            obj.buffered_tasks(end+1) = DQ_DO_Finite(options.numsamples, options.rate, 'clock_source', options.clock, 'trigger_source', options.trigger_source);
            task_out = obj.buffered_tasks(end);
            obj.CheckHandle(task_out);
        end

        function channel_out = Attach_Channel(obj, taskindex, channel_name, phys_channel, options)
            arguments
                obj DAQ
                taskindex
                channel_name
                phys_channel
                options.data = []
                options.max = obj.buffered_tasks(taskindex).max;
                options.min = obj.buffered_tasks(taskindex).min;
            end
            obj.buffered_tasks(taskindex).Add_Channel(channel_name, phys_channel, ...
                'min', options.min, 'max', options.max, 'data', options.data);
            channel_out = obj.buffered_tasks(taskindex).channels(end);
        end

        function channel_out = Attach_Channel_THandle(obj, task_handle, channel_name, phys_channel, options)
            arguments
                obj DAQ
                task_handle
                channel_name
                phys_channel
                options.data = []
                options.max = task_handle.max;
                options.min = task_handle.min;
            end
            task_handle.Add_Channel(channel_name, phys_channel, ...
                'min', options.min, 'max', options.max, 'data', options.data);
            channel_out = task_handle.channels(end);
        end


        function CheckHandle(obj, task)
            if sum(strcmp(task, {obj.buffered_tasks.taskHandle})) + sum(strcmp(task, {obj.counter_outputs.taskHandle})) > 1
                warning('Repeat task handle detected. Reallocating Handle')
                task.CreateTask();
            end
        end

        function Fix_Repeat_Handles(obj)
            for i = 1:numel(obj.buffered_tasks)
                if sum(strcmp(obj.buffered_tasks(i).taskHandle, {obj.buffered_tasks.taskHandle})) > 1
                    warning('Repeat task handle detected. Reallocating Handle')
                    obj.buffered_tasks(i).CreateTask();
                end
            end
        end

        function Get_Device_information(obj)
            dlist = daqlist("ni");
            obj.Device_List = table2array(dlist(:, 1));
            ai_pnum = 0;
            ao_pnum = 0;
            dio_pnum = 0;
            Counter_pnum = 0;
            for i = 1:size(obj.Device_List, 1)
                Device_Info = dlist{i, 'DeviceInfo'};
                DeviceID = dlist{i, 'DeviceID'};

                subsystemNames = strings(1, numel(Device_Info.Subsystems)); % initialize empty string array
                for q = 1:numel(Device_Info.Subsystems)
                    subsystemNames(q) = Device_Info.Subsystems(q).SubsystemType;
                end

                ai_port_idx = find(subsystemNames == "AnalogInput");
                if ~isempty(ai_port_idx)
                    ai_port_list = Device_Info.Subsystems(ai_port_idx).ChannelNames;
                    for j = 1:numel(ai_port_list)
                        obj.AI_Ports(ai_pnum+j).Device = char(DeviceID);
                        obj.AI_Ports(ai_pnum+j).PortID = ai_port_list{j};
                    end
                    ai_pnum = ai_pnum + j;
                end

                ao_port_idx = find(subsystemNames == "AnalogOutput");
                if ~isempty(ao_port_idx)
                    ao_port_list = Device_Info.Subsystems(ao_port_idx).ChannelNames;
                    for j = 1:numel(ao_port_list)
                        obj.AO_Ports(ao_pnum+j).Device = char(DeviceID);
                        obj.AO_Ports(ao_pnum+j).PortID = ao_port_list{j};
                    end
                    ao_pnum = ao_pnum + j;
                end

                dio_port_idx = find(subsystemNames == "DigitalIO");
                if ~isempty(dio_port_idx)
                    dio_port_list = Device_Info.Subsystems(dio_port_idx).ChannelNames;
                    for j = 1:numel(dio_port_list)
                        obj.DIO_Ports(dio_pnum+j).Device = char(DeviceID);
                        obj.DIO_Ports(dio_pnum+j).PortID = dio_port_list{j};
                    end
                    dio_pnum = dio_pnum + j;
                end

                counters_port_idx = find(subsystemNames == "CounterInput");
                if ~isempty(counters_port_idx)
                    Counters = Device_Info.Subsystems(counters_port_idx).ChannelNames;
                    for j = 1:numel(Counters)
                        obj.Counters(Counter_pnum+j).Device = char(DeviceID);
                        obj.Counters(Counter_pnum+j).PortID = Counters{j};
                    end
                    Counter_pnum = Counter_pnum + j;
                end
                if isempty(obj.Terminals)
                    obj.Terminals = Device_Info.Terminals;
                else
                    obj.Terminals = [obj.Terminals; Device_Info.Terminals];
                end
            end
        end

    end

    methods (Static)
        function List = Get_NI_Portlist(Ports)
            List = '';
            for i = 1:numel(Ports)
                List = strcat(List, Ports(i).Device, '/', Ports(i).PortID, ',');
            end
            List = char(List);
            List(end) = [];
        end

        function assign_counter_to_clock(buffered_task, counter_task)
            buffered_task.clock = strcat('/', counter_task.counter, 'InternalOutput');
        end
    end

end
