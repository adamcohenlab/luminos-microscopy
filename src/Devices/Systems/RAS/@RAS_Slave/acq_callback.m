function acq_callback(obj)
drawnow;
pause(.1);
PMT_split = [obj.PMT_Channel.data(3:2:end), 0];
PD_split = obj.PD_Channel.data(1:2:end);
PD_BG = obj.PD_Channel.data(2:2:end);
PD_split(2:end) = PD_split(2:end) + (PD_BG(1:end-1) + PD_BG(2:end)) / 2;
PD_split(1) = PD_split(2); %Will always be out of SLM face.
PMT_split = obj.PMT_Channel.data;
PD_split = obj.PD_Channel.data;
plot(obj.scope_ax, PMT_split)
hold(obj.scope_ax, 'on')
plot(obj.scope_ax, PD_split)
plot(obj.scope_ax, repmat(obj.galvo_chan.data, [1, numel(PMT_split) / numel(obj.galvo_chan.data)]))
plot(obj.scope_ax, obj.galvo_fb_channel.data)
legend(obj.scope_ax, {'PMT', 'Photodiode', 'Drive WFM', 'Feedback WFM'}, 'TextColor', [.7, .7, .7])
hold(obj.scope_ax, 'off')
end
