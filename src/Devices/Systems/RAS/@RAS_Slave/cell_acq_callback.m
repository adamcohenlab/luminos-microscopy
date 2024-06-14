function obj = cell_acq_callback(obj, src, evt)
PMT_split = obj.PMT_Channel.data(2:2:end);
PD_split = obj.PD_Channel.data(1:2:end);
PD_BG = obj.PD_Channel.data(2:2:end);
PD_split(2:end) = PD_split(2:end) - (PD_BG(1:end-1) + PD_BG(2:end)) / 2;
PD_split(1) = PD_split(2); %Will always be out of SLM face.
normalized_data = obj.Normalize_PMT_w_PD(PMT_split, PD_split);
stacked_data = reshape(normalized_data, [samps_per_cycle / 2, numcycles]);
hold(obj.data_ax, 'on')
for i = 1:numel(obj.cellgroups)
    obj.cellgroups{i}.rawdata = stacked_data(obj.cellgroups{i}.samp_indices(:)'*(1:obj.numcycles), :);
    obj.cellgroups{i}.weights = sum(obj.cellgroups{i}.rawdata, 2) / sum(obj.cellgroups{i}.rawdata(:));
    obj.cellgroups{i}.data = obj.cellgroups{i}.weights * obj.cellgroups{i}.rawdata;
    plot(obj.data_ax, obj.cellgroups{i}.data, 'DisplayName', ['Cell_', numtsrt(i)])
end
hold(obj.data_ax, 'off')
drawnow
end