% The DQ_CO_Ticks class represents a data acquisition task for generating and
% capturing counter/tick signals.

classdef DQ_CO_Ticks < matlab.mixin.Heterogeneous & handle
    properties
        name
        data
        regeneration_mode
        channels_configured
        lowticks
        highticks
        delay
        counter_chan
        tickinput_chan
        trigger_source
        complete
        task_type
    end
    properties (Transient)
        objPointer = 0
        taskHandle = 0
    end
    methods
        function obj = DQ_CO_Ticks(name, counter, tickinput, lowticks, highticks, options)
            arguments
                name
                counter
                tickinput
                lowticks
                highticks
                options.trigger_source = '';
                options.start_delay = 0;
            end
            obj.task_type = 'coc';
            obj.name = name;
            obj.delay = int32(0);
            obj.counter_chan = counter;
            obj.tickinput_chan = tickinput;
            obj.lowticks = lowticks;
            obj.highticks = highticks;
            obj.channels_configured = 0;
            obj.trigger_source = options.trigger_source;
            obj.objPointer = DAQ_MEX('new', uint16(1), char(obj.task_type));
            obj.CreateTask();
        end

        function delete(obj)
            if ~isempty(obj.objPointer) && obj.objPointer
                error = DAQ_MEX('Delete_Handle', obj.objPointer);
                obj.ErrorCheck(error);
            end
            %"Deleted DQ_CO_Ticks"
        end
        function obj = CreateTask(obj)
            [status, thandle] = DAQ_MEX('Generate_taskHandle', obj.objPointer);
            obj.taskHandle = thandle;
            obj.ErrorCheck(status);
        end
        function obj = Configure_Channels(obj)
            status = DAQ_MEX('Add_Output_Counter', obj.objPointer, char(obj.tickinput_chan), ...
                char(obj.name), char(obj.counter_chan), int32(obj.lowticks), int32(obj.highticks), int32(obj.delay));
            obj.ErrorCheck(status);
            obj.channels_configured = 1;
        end
        function obj = AddTrigger(obj, source, trigedge)
            if strcmp(trigedge, 'falling')
                warning('Invalid trigger edge type. falling edge not yet enabled. Defaulting to rising.');
            end
            status = DAQ_MEX('Attach_Trigger', obj.objPointer, char(source));
            obj.ErrorCheck(status);
            obj.trigger_source = source;
        end
        function obj = Start(obj)
            obj.complete = false;
            status = DAQ_MEX('Start_Task', obj.objPointer);
            obj.ErrorCheck(status);
        end
        function obj = StopTask(obj)
            status = DAQ_MEX('Stop_Task', obj.objPointer);
            obj.ErrorCheck(status);
        end
        function ClearTask(obj)
            [status] = DAQ_MEX('Clear_Task', obj.objPointer);
            obj.ErrorCheck(status);
        end
        function ResetTask(obj, options)
            arguments
                obj DQ_CO_Ticks
                options.highticks = obj.highticks;
                options.lowticks = obj.lowticks;
                options.tickinput_chan = obj.tickinput_chan;
                options.start_delay = obj.delay;
                options.configure_now = false;
            end
            obj.highticks = options.highticks;
            obj.lowticks = options.lowticks;
            obj.tickinput_chan = options.tickinput_chan;
            obj.delay = options.start_delay;
            obj.ClearTask();
            obj.CreateTask();
            if options.configure_now
                obj.Configure_Channels();
            end
        end
    end

    methods (Static)
        function ErrorCheck(status)
            daq.ni.utility.throwOrWarnOnStatus(status);
        end
        function obj = loadobj(s)
            %"Loading DQ_CO_Ticks"
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
