function Run_Spec_Routine(obj, low_nm, high_nm, power)
obj.acq_listener.Enabled = false;
%    obj.AO_Task.Start();
obj.AI_Task.numsamples = 100 * numel(obj.galvo_chan.data);
obj.AI_Task.ClearTask();
obj.AI_Task.Configure_Task();
k = 1;
for i = 1:3
    for j = low_nm:high_nm
        %           obj.Stage.Step_Fixed(1,10);
        obj.Set_Laser_Gate(0);
        obj.Set_Wave_Pow(j, power);
        obj.Set_Wavelength(j);
        pause(.5)
        obj.Set_Laser_Gate(1);
        pause(1)
        obj.AI_Task.Start();
        while obj.AI_Task.complete == false
            pause(.1)
        end
        PMT_split = obj.PMT_Channel.data(2:2:end);
        PD_split = obj.PD_Channel.data(1:2:end);
        PD_BG = obj.PD_Channel.data(2:2:end);
        PD_split(2:end) = PD_split(2:end) + (PD_BG(1:end-1) + PD_BG(2:end)) / 2;
        PD_split(1) = PD_split(2); %Will always be out of SLM face.
        obj.spec_data(k).wavelength = j;
        obj.spec_data(k).PD = PD_Data;
        obj.spec_data(k).PMT = PMT_Data;

        plot(obj.scope_ax, PD_split)
        hold(obj.scope_ax, 'on')
        plot(obj.scope_ax, PMT_split)
        plot(obj.scope_ax, repmat(obj.galvo_chan.data(1:2:end), [1, numel(PMT_split) / numel(obj.galvo_chan.data(1:2:end))]))
        plot(obj.scope_ax, obj.galvo_fb_channel.data(1:2:end))
        legend(obj.scope_ax, {'PMT', 'Photodiode', 'Drive WFM', 'Feedback WFM'}, 'TextColor', [.7, .7, .7])
        hold(obj.scope_ax, 'off')

        k = k + 1;
    end
end
end
