classdef DQ_Buffered_Task < matlab.mixin.Heterogeneous & handle
    properties
        channels = DQ_Channel.empty;
        task_type
        aibuffer_pad
        timeout
        numsamples
        rate
        clock_type
        clock_source
        clockedge
        trigger_source
        rerouted_source
        triggeredge
        task_configured
        clock_group
        min
        max
    end
    properties (Transient)
        taskHandle
        objPointer
        tmr
    end
    properties (SetObservable, AbortSet)
        complete
    end
    methods
        function obj = DQ_Buffered_Task(numsamples, rate, task_type, op_pass)
            arguments
                numsamples
                rate
                task_type
                op_pass
            end
            obj.objPointer = DAQ_MEX('new', uint16(1), char(task_type));
            obj.task_type = task_type;
            obj.numsamples = numsamples;
            obj.rate = rate;
            obj.clockedge = op_pass.clockedge;
            obj.clock_source = char(op_pass.clock_source);
            obj.trigger_source = char(op_pass.trigger_source);
            obj.triggeredge = op_pass.triggeredge;
            obj.timeout = op_pass.timeout;
            obj.aibuffer_pad = op_pass.aibuffer_pad;
            obj.min = op_pass.min;
            obj.max = op_pass.max;
            obj.task_configured = 0;
            obj.complete = false;
            obj.clock_group = 0;
            obj.CreateTask();
        end

        function delete(obj)
            if ~isempty(obj.objPointer) && obj.objPointer
                error = DAQ_MEX('Delete_Handle', obj.objPointer);
                obj.ErrorCheck(error);
            end
            if ~isempty(obj.tmr)
                delete(obj.tmr)
            end
            %"Deleted DQ_Buffered_Task"
        end

        function obj = CreateTask(obj)
            [status, thandle] = DAQ_MEX('Generate_taskHandle', obj.objPointer);
            obj.taskHandle = thandle;
            obj.ErrorCheck(status);
        end

        function obj = Configure_Task(obj)
            if obj.task_configured
                obj.ResetTask();
                warning('Task was already configured.')
            end
            obj.Configure_Channels(); %Defined in subclass
            obj.Configure_Timing();
            obj.Create_Timer();
            obj.task_configured = true;
            obj.complete = false;
        end

        function obj = Configure_Timing(obj)
            ctriggersource = char(obj.trigger_source);
            cclocksource = char(obj.clock_source);
            if ~strcmp(obj.clock_source, ' ')
                if ~strcmp(cclocksource(1), '/')
                    obj.clock_source = ['/', obj.clock_source];
                end
            end
            status = DAQ_MEX('Configure_Clock', obj.objPointer, ...
                char(obj.clock_source), double(obj.rate), uint32(obj.numsamples+obj.aibuffer_pad));
            obj.ErrorCheck(status);
            if strcmp(obj.trigger_source, '') == false
                if ~strcmp(ctriggersource(1), '/')
                    obj.trigger_source = ['/', obj.trigger_source];
                end
                obj = obj.AddTrigger(obj.trigger_source, 'rising');
            end
        end

        function chan_out = Add_Channel(obj, name, phys_channel, options)
            arguments
                obj DQ_Buffered_Task
                name
                phys_channel
                options.min = obj.min;
                options.max = obj.max;
                options.data = [];
            end
            obj.channels(end+1).name = name;
            obj.channels(end).phys_channel = phys_channel;
            obj.channels(end).min = options.min;
            obj.channels(end).max = options.max;
            if (numel(options.data) == obj.numsamples) || logical(strcmp(obj.task_type(2), 'i'))
                obj.channels(end).data = options.data;
            else
                warning('Channel data does not match rest of task. Rejecting Channel addition. Resize and re-add channel')
                obj.channels(end) = [];
            end
            chan_out = obj.channels(end);
        end

        function obj = AddTrigger(obj, source, trigedge)
            if strcmp(trigedge, 'falling')
                warning('Invalid trigger edge type. falling edge not yet enabled. Defaulting to rising.');
            end
            status = DAQ_MEX('Attach_Trigger', obj.objPointer, char(source));
            obj.ErrorCheck(status);
            obj.triggeredge = 'rising';
            obj.trigger_source = source;
        end

        function obj = Create_Timer(obj)
            if ~isempty(obj.tmr)
                delete(obj.tmr)
            end
            obj.tmr = timer('BusyMode', 'queue', ...
                'StartDelay', round(obj.numsamples/double(obj.rate), 3)); %round(x,N) rounds x to N decimal precision
            obj.tmr.TimerFcn = @obj.timercallback;
        end

        function obj = Start(obj)
            obj.complete = false;
            status = DAQ_MEX('Start_Task', obj.objPointer);
            obj.ErrorCheck(status);
            start(obj.tmr);
        end

        function obj = StopTask(obj)
            status = DAQ_MEX('Stop_Task', obj.objPointer);
            obj.ErrorCheck(status);
            obj.tmr.stop();
        end

        function ClearTask(obj)
            [status] = DAQ_MEX('Clear_Task', obj.objPointer);
            obj.ErrorCheck(status);
            obj.task_configured = false;
        end

        function Connect_Terminals(obj, Source_Terminal, Destination_Terminal)
            status = DAQ_MEX('Connect_Terminas', obj.objPointer, char(Source_Terminal), char(Destination_Terminal));
            obj.ErrorCheck(status);
        end

        function ResetTask(obj)
            obj.ClearTask();
            obj.CreateTask();
        end
    end

    methods (Static)
        function ErrorCheck(status)
            daq.ni.utility.throwOrWarnOnStatus(status);
        end
        function obj = loadobj(s)
            if isstruct(s)
                "Is struct";
                error("Unable to construct DQ_CO_Ticks from saved data");
            else
                mc = metaclass(s);
                "Is obj";
                for i = 1:numel(mc.PropertyList)
                    %Ensure that there are no self-references in timer
                    %functions
                    if isa(s.(mc.PropertyList(i).Name), 'timer')
                        s.(mc.PropertyList(i).Name).TimerFcn = [];
                    end
                    if mc.PropertyList(i).Transient
                        %Delete transient timers before clearing the
                        %property to avoid leaving orphaned timers
                        if isa(s.(mc.PropertyList(i).Name), 'timer')
                            delete(s.(mc.PropertyList(i).Name));
                        end
                        %Clear transient properties
                        s.(mc.PropertyList(i).Name) = [];
                    end
                end
                obj = s;
            end
        end
    end
end