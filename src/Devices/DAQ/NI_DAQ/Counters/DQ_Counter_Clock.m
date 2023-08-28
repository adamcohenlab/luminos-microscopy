classdef DQ_Counter_Clock < DQ_CO_Ticks
    properties
        Property1
    end

    methods
        function obj = DQ_Counter_Clock(name, counter, tickinput, division_factor, options)
            arguments
                name
                counter
                tickinput
                division_factor
                options.trigger_source = '';
                options.start_delay = 4;
            end
            obj@DQ_CO_Ticks(name, counter, tickinput, division_factor/2, division_factor/2, 'trigger_source', options.trigger_source, 'start_delay', options.start_delay);
        end

        function ResetTask(obj, options)
            arguments
                obj DQ_Counter_Clock
                options.division_factor = 2 * obj.highticks;
                options.tickinput_chan = obj.tickinput_chan;
                options.start_delay = obj.delay;
                options.configure_now = false;
            end
            ResetTask@DQ_CO_Ticks(obj, 'highticks', options.division_factor/2, 'lowticks', options.division_factor/2, ...
                'tickinput_chan', options.tickinput_chan, 'start_delay', options.start_delay, 'configure_now', options.configure_now);
        end
    end
end
