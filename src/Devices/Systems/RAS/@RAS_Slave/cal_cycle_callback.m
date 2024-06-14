function cal_cycle_callback(obj)
if obj.Tuning_Mode == false
    PMT_split = obj.PMT_Channel.data(3:2:end);
    PMT_split = [PMT_split, 0];
    PD_split = [0, (obj.PD_Channel.data(3:2:end) - (obj.PD_Channel.data(2:2:end-1) + obj.PD_Channel.data(4:2:end)) / 2)];
    PD_split(1) = PD_split(2);
    Galvo_fb = obj.galvo_fb_channel.data(1:2:end);
    Galvo_in = obj.galvo_chan.data(1:2:end);
    if obj.SLM_cal_pattern == 1
        [obj.pup, obj.pdown] = plot_RAS_galvo_cal(PMT_split, Galvo_fb, obj.cal_ax(1), obj.cal_ax(2), .005);
    elseif obj.SLM_cal_pattern == 2
        [obj.pup, obj.pdown] = plot_RAS_galvo_cal(PMT_split, Galvo_fb, obj.cal_ax(1), obj.cal_ax(2), .005);
        obj.SLM_cal_pattern = 0;
    end
end
end