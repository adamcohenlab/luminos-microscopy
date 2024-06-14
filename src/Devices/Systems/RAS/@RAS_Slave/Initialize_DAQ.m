function Initialize_DAQ(obj)

galvo_phys_channel = 'Dev2/ao0';
pmt_phys_channel = 'Dev2/ai0';
pd_phys_channel = 'Dev2/ai7';
galvo_fb_phys_channel = 'Dev2/ai3';

obj.dq_session.rate = 1e6;
obj.dq_session.trigger = '/Dev2/ctr0InternalOutput';
obj.dq_session.clock = '/Dev2/PFI0';
obj.dq_session.numsamples = numel(obj.waveform);
obj.dq_session.DAQ_Master = false;

obj.Laser_PP_Sync = '/Dev2/PFI1';
obj.trigger_counter = DQ_CO_Ticks('Galvo_Counter', 'Dev2/ctr0', ...
    obj.dq_session.clock, round(numel(obj.waveform)/2), ...
    numel(obj.waveform)-round(numel(obj.waveform)/2), 'trigger_source', obj.Laser_PP_Sync);
obj.trigger_counter.Configure_Channels();
obj.trigger_counter.Start();

obj.AO_Task = obj.dq_session.Add_AO_Wavegen_Task();
obj.galvo_chan = obj.AO_Task.Add_Channel('galvo_out', galvo_phys_channel, 'data', obj.waveform);
obj.AO_Task.regeneration_mode = 'FIFO';
obj.AO_Task.Configure_Task();

obj.AI_Task = obj.dq_session.Add_AI_Task(); %Enhancement: Change to counter channel clocking for offset
obj.PMT_Channel = obj.AI_Task.Add_Channel('PMT_Channel', pmt_phys_channel);
obj.PD_Channel = obj.AI_Task.Add_Channel('PD_Channel', pd_phys_channel);
obj.galvo_fb_channel = obj.AI_Task.Add_Channel('Galvo_fb', galvo_fb_phys_channel);
end
