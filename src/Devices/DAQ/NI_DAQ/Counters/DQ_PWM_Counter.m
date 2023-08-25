classdef DQ_PWM_Counter < DQ_CO_Ticks
    properties
        duty_cycle
    end

    methods
        function obj = DQ_PWM_Counter(name, counter, clock, clk_division, duty_cycle, options)
            arguments
                name
                counter
                clock
                clk_division
                duty_cycle
                options.trigger_source = '';
                options.start_delay = 0;
            end
            high_ticks = round(duty_cycle*clk_division);
            low_ticks = clk_division - high_ticks;
            obj@DQ_CO_Ticks(name, counter, clock, low_ticks, high_ticks, 'trigger_source', ...
                options.trigger_source, 'start_delay', options.start_delay);
            obj.duty_cycle = high_ticks / clk_division;
        end

        function Update_Division(obj, clk_division)
            obj.high_ticks = round(obj.duty_cycle*clk_division);
            obj.low_ticks = clk_division - high_ticks;
            obj.duty_cycle = high_ticks / clk_division;
        end

    end

end