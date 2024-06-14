function obj = Spec_Callback(obj, src, evt)
PMT_split = obj.PMT_Channel.data(2:2:end);
PD_split = obj.PD_Channel.data(1:2:end);
PD_BG = obj.PD_Channel.data(2:2:end);
PD_split(2:end) = PD_split(2:end) - (PD_BG(1:end-1) + PD_BG(2:end)) / 2;
PD_split(1) = PD_split(2); %Will always be out of SLM face.
normalized_data = obj.Normalize_PMT_w_PD(PMT_split, PD_split);
end