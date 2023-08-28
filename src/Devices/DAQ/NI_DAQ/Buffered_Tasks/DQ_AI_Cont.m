classdef DQ_AI_Cont < DQ_Buffered_Task

    properties
        sampcountavail
        channels_configured
        tax
        datatile
        logging_mode
        logfile
        store_all_memory
        plotdata
        q1 parallel.pool.DataQueue;
        q2 = parallel.pool.DataQueue.empty;
        parfuture;
        datacallback;
        custom_processing; %Function handle to be passed to worker on parpool.
        custom_outdata;
        qlistener;
        q2listener;
        parfinished;
        inworker;
        running;
    end

    methods
        function obj = DQ_AI_Cont(numsamples, rate, options)
            arguments
                numsamples
                rate
                options.timeout = 10.0;
                options.trigger_source = '';
                options.triggeredge = 'rising';
                options.rerouted_source = '';
                options.clock_source = ' ';
                options.clockedge = 'rising';
                options.read_data_threshold = rate;
                options.aibuffer_pad = 1e6;
                options.max = 10;
                options.min = -10;
                options.logging_mode = 'none';
                options.logfile = '';
                options.store_all_memory = false;
                options.q = parallel.pool.DataQueue();
                options.Create_Task = 1;
            end
            error('Not Currently Functional')
            op_pass = options;
            task_type = 'aic';
            obj@DQ_Buffered_Task(numsamples, rate, task_type, op_pass);
            obj.sampcountavail = uint32(0);
            obj.clock_type = 'continuous';
            obj.channels_configured = 0;
            obj.Create_Timer(); %Does this do anything?
            obj.logging_mode = options.logging_mode;
            obj.logfile = options.logfile;
            obj.task_type = task_type;
            obj.q1 = parallel.pool.DataQueue;
            obj.qlistener = afterEach(obj.q1, @(data)Channel_Copy(obj, data));
            obj.inworker = false;
        end

        function obj = Configure_Channels(obj)
            channel_namelist = strjoin({obj.channels.name}, ',');
            xyz = [obj.channels.phys_channel];
            phys_channellist = char(strjoin(string(xyz), ','));
            status = DAQ_MEX('Add_Analog_Input_Channel', obj.objPointer, phys_channellist, ...
                channel_namelist, double(obj.min), double(obj.max), int32(-1), int32(obj.numsamples));
            obj.ErrorCheck(status);
        end

        function obj = Reconfigure_Task(obj, options)
            arguments
                obj
                options.numsamples = obj.numsamples
                options.max = obj.max;
                options.min = obj.min;
                options.rate = obj.rate;
            end
            obj.numsamples = buffer_size;
            obj.max = options.max;
            obj.min = options.min;
            obj.rate = options.rate;
            obj.ClearTask();
            obj.Configure_Task();
            obj.Start();
        end

    end
end
