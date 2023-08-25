classdef (Abstract) DMD < Patterning_Device
    properties (Transient)
        trigger_channel
    end
    properties (SetObservable = true, Transient)
        wavegen Compact_Waveform_Generator
    end
    properties (SetObservable = true)
        video_stack
    end
    methods (Abstract)
        Write_Static(obj);
        Write_Video(obj);
        Write_Stack(obj);
    end
    methods
        function obj = DMD(Initializer)
            obj@Patterning_Device(Initializer);
            obj.wavegen = Compact_Waveform_Generator();
            if obj.debug_mode == 1
                figure
                subplot(1, 2, 1)
                title('Simulated DMD Face')
                colormap(gray);
                obj.demo_ax(1) = gca;
                subplot(1, 2, 2)
                obj.demo_ax(2) = gca;
                title('Simulated image plane')
            end
        end
        
        function Write_Stack_JS(obj, stack)
            % stack is (frame,x,y)
            obj.pattern_stack = stack;
            obj.Write_Stack();
            
        end
        
        function Add_Pattern_to_Alignment(obj, name)
            obj.Alignment_Pattern_Stack(end+1).pattern = obj.Target;
            obj.Alignment_Pattern_Stack(end).name = name;
        end
        
        function Project_Aligment_Pattern(obj, name)
            pattern = obj.Alignment_Pattern_Stack(strcmp([obj.Alignment_Pattern_Stack.name], name)).pattern;
            if ~isempty(pattern)
                obj.Target = pattern;
                obj.Write_Static();
            else
                display('Pattern Not Found!')
            end
        end
        
        function Write_White(obj)
            obj.Target = true(obj.Dimensions);
            obj.Write_Static();
            
        end
        
        % Project stored calibration pattern. Optional num_points_to_show
        % argument allows for showing only a prefix subset of the full
        % calibration pattern (in order, e.g. to step through the
        % calibration pattern interactively point-by-point.
        function Project_Cal_Pattern(obj, num_points_to_show)
            arguments
                obj DMD;
                num_points_to_show = -1;
            end
            if num_points_to_show < 0
                num_points_to_show = size(obj.calpoints,1);
            end
            obj.Target=obj.GenTargetFromSpots(obj.calpoints(1:num_points_to_show,:),obj.Dimensions,10);
            obj.Write_Static();
        end
        
        function Generate_PWM_Amplitude_Stimulation(obj, options)
            arguments
                obj
                options.bitplanes = 8
                options.waveform_block = obj.wavegen.Get_Waveform_Mat();
            end
            bitplanes = options.bitplanes;
            waveform_block = options.waveform_block;
            assert(size(waveform_block, 1) == size(obj.pattern_stack, 3), 'Mismatch between number of patterns and number of waveforms in DMD Device')
            vidstack = false(size(obj.Target, 1), size(obj.Target, 2), size(waveform_block, 2)*bitplanes);
            sawval = mod((1:size(waveform_block, 2) * bitplanes)-1, bitplanes) / (bitplanes - 1);
            testbool = waveform_block(:, floor((0:size(waveform_block, 2) * bitplanes - 1)/bitplanes+1)) > sawval;
            pstack = logical(obj.pattern_stack);
            expanded_pstack = permute(repmat(pstack, 1, 1, 1, size(testbool, 2)), [3, 4, 1, 2]); %Matrix trickery to avoid a for loop
            obj.video_stack = squeeze(permute(squeeze(any(testbool.*expanded_pstack, 1)), [3, 2, 1]));
        end
        function Generate_Dilating_Stimulation(obj, waveform_block)
            assert(size(waveform_block, 2) == size(obj.pattern_stack, 3), 'Mismatch between number of patterns and number of waveforms in DMD Device')
            obj.video_stack = zeros(size(obj.Target, 1), size(obj.Target, 2), size(waveform_block, 2));
            subframe = zeros(size(obj.Target, 1), size(obj.Target, 2), size(waveform_block, 1));
            for i = 1:size(waveform_block, 2)
                for j = 1:size(waveform_block, 1)
                    se = strel('disk', waveform_block(j, i), 0);
                    subframe(:, :, j) = imdilate(obj.pattern_stack(:, :, j), se);
                end
                obj.video_stack(:, :, i) = sum(subframe, 3) > 0;
            end
        end
    end
    methods (Static)
        function Target = GenTargetFromSpots(spotcoords, Dimensions, Width)
            [X, Y] = meshgrid(1:Dimensions(1), 1:Dimensions(2));
            bool_mask = @(x0, y0, w0) ((X - x0).^2 + (Y - y0).^2) < w0^2;
            Target = zeros(Dimensions)';
            for i = 1:size(spotcoords, 1)
                Target = Target | bool_mask(spotcoords(i, 1), spotcoords(i, 2), Width); %element-wise OR operator used
            end
        end
    end
end
