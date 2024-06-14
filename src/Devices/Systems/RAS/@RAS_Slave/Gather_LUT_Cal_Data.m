function Gather_LUT_Cal_Data(obj, wavelength_list)
%obj.SLM.load_linear_lut();
tic
figure
showax = gca;
%obj.data_plt=plot(zeros(1,30e6));
%obj.Launch_Alignment_Mode();
obj.LUT_Data = RAS_SLM_LUT_Data(wavelength_list);
obj.Set_Wave_Pow(wavelength_list(1), .25);
obj.wavelength = wavelength_list(1);
pause(1);
obj.AI_Task.rate = 1e6;
obj.AI_Task.numsamples = 1e6;
obj.AI_Task.clock_source = ' ';
%obj.AI_Task.trigger_source='';
obj.AI_Task.Configure_Task();
trace_vec = 1:obj.AI_Task.numsamples;
samp_points = [6372:6455, 23925:23994]';
expanded_points = any(mod(trace_vec, obj.AO_Task.numsamples*10) == samp_points);
for i = 1:numel(wavelength_list)
    obj.Set_Wave_Pow(wavelength_list(i), .25);
    for k = 1:32
        j = 200;
        obj.gval = j;
        obj.SLM.Display_Masked_LUT_Cal(j, (1:16)+16*(k - 1));
        pause(1);
        obj.ready = false;
        obj.AI_Task.StopTask();
        obj.AI_Task.Start();
        while (obj.AI_Task.complete == false)
            pause(.1)
        end
        plot(showax, obj.PD_Channel.data(:));
        drawnow
        pause(.1)
        hold(showax, 'on')
        samp_points = input('sample point vector');
        expanded_points = any(mod(trace_vec, obj.AO_Task.numsamples*10) == samp_points);
        plot(showax, expanded_points*.1+.17)
        hold(showax, 'off')
        drawnow
        pause(.1)

        for j = 0:255
            obj.gval = j;
            obj.SLM.Display_Masked_LUT_Cal(j, (1:16)+16*(k - 1));
            pause(1);
            obj.ready = false;
            obj.AI_Task.StopTask();
            obj.AI_Task.Start();
            while (obj.AI_Task.complete == false)
                pause(.1)
            end
            plot(showax, obj.PD_Channel.data(:));
            hold(showax, 'on')
            plot(showax, expanded_points*.1+.17)
            hold(showax, 'off')
            drawnow
            pause(.1)
            obj.LUT_Data.Append_Mean_Trace(k, obj.wavelength, obj.gval, mean(obj.PD_Channel.data(expanded_points)));
            j
        end
        figure
        imagesc(obj.LUT_Data.Phase_Maps(i).map)
        toc
    end

end
end