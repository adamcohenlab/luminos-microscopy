storedata = zeros(1001, 3000);
wfm_fb_store = zeros(1001, 3000);
vshift_vec = 8e-4; %6e-4:.5e-4:10e-4;
vstoredata = zeros(numel(vshift_vec), 3000);
figure
liveax = gca;

%%
wfm_points = numel(xx.RAS_dev.galvo_chan.data);
for i = 1:numel(vshift_vec)
    vshift = vshift_vec(i); %.0016
    tgt_v = mean([xx.RAS_dev.SLM_row_V(1:512); xx.RAS_dev.SLM_row_V(1024:-1:513)], 1) + vshift;
    Vdiff = mean(diff(xx.RAS_dev.SLM_row_V(1:512)));
    samp_delay = mean(xx.RAS_dev.SLM_row_V(1:512)-xx.RAS_dev.SLM_row_V(1024:-1:513)) / Vdiff;
    SLM_numrows = 512;
    padpoints = round((wfm_points - (SLM_numrows * 4))/4);
    pk_d = Vdiff * padpoints / 2;
    target_indices = [1, padpoints + (2:2:1024), (2 * padpoints + 1024), (2 * padpoints + 1025), (3 * padpoints + 1024) + (2:2:1024), 4 * padpoints + 2048];
    target_wfm_points = [min(tgt_v) - pk_d, tgt_v(1:512), max(tgt_v) + pk_d, max(tgt_v) + pk_d, tgt_v(512:-1:1), min(tgt_v) - pk_d];
    wfm_points = max(target_indices);
    tiled_indices = [target_indices, target_indices + wfm_points, target_indices + 2 * wfm_points];
    tiled_points = [target_wfm_points, target_wfm_points, target_wfm_points];
    input('Confirm Shutter Closed by pressing enter in the prompt')
    xx.RAS_dev.splined_delay = 107640 + 20000 + 600 + 94 + 188 + 25; %-i*31;
    splined_tiled_target = makima(tiled_indices, tiled_points, 1:.001:wfm_points*3);
    splined_target = splined_tiled_target((wfm_points * 1000 + 1):(wfm_points * 2000));
    updated_drive_splined = circshift(splined_target, -xx.RAS_dev.splined_delay);

    updated_drive = updated_drive_splined(1:1000:end);
    xx.RAS_dev.galvo_chan.data = updated_drive;
    updated_waveform = updated_drive;
    tgt_wfm_data = updated_drive;
    xx.RAS_dev.AO_Task.ClearTask();
    xx.RAS_dev.AI_Task.complete = false;
    xx.RAS_dev.AO_Task.Configure_Task();
    pause(.8)
    pause(.5);
    xx.RAS_dev.AO_Task.Start();
    input('Confirm Galvos Are running by pressing enter in the prompt')
    xx.RAS_dev.OPA.Set_Main_Shutter(1);
    pause(3);
    i
    xx.RAS_dev.AI_Task.Start();
    drawnow
    while ~xx.RAS_dev.AI_Task.complete
        pause(.1)
    end
    xx.RAS_dev.AI_Task.StopTask();
    plot(liveax, mean(reshape(xx.RAS_dev.PMT_Channel.data, [3000, 1000]), 2))
    drawnow
    vstoredata(i, :) = mean(reshape(xx.RAS_dev.PMT_Channel.data, [3000, 1000]), 2);
    wfm_fb_store(i, :) = updated_drive;
    xx.RAS_dev.OPA.Set_Main_Shutter(0);
end

% %%i was 84
% %%
% shifted_reference=zeros(85,numel(splined_target));
% sync_reference=zeros(85,3000);
% for i=0:84
%     part_delay=-1*i*31;
%     shifted_reference(i+1,:)=circshift(splined_target,-part_delay);
%     i
% end
% %%
% smoothed_response=smoothdata(vstoredata(1:end-1,pklist),1,'gaussian',10);
% for i=1:512
%     [val,index]=max(smoothed_response(:,i));
%     pkshiftindex(i)=index;
%     shift_val(i)=vshift_vec(index)+pshiftval(i);
% end

%%
LUTMat = zeros(32, 256, 3000);
sumdata = zeros(32, 256);
std_data = zeros(32, 256);
xx.RAS_dev.SLM.load_linear_lut();
xx.RAS_dev.SLM.custom_lut_loaded = false;
binwidth = 16;
pause(1)

%%
figure
liveax = gca;

for j = 1:32

    pause(1);
    %   xx.RAS_dev.SLM.Display_Masked_LUT_Cal(100,(1:16)+16*(j-1));
    pause(.5)
    xx.RAS_dev.Acquire_Trace(100);
    while ~xx.RAS_dev.AI_Task.complete
        drawnow
    end
    mdata = mean(reshape(xx.RAS_dev.PD_Channel.data, [3000, 100]), 2);
    plt = plot(liveax, mdata);
    hold(liveax, 'on')
    target_indices = [1270 - 2 * ((0:15) + 16 * (j - 1)), 1730 + 2 * ((0:15) + 16 * (j - 1))];
    plt2 = plot(liveax, target_indices, mdata(target_indices), '*');
    hold(liveax, 'off')
    tic
    for i = 0:255
        %        xx.RAS_dev.SLM.Display_Masked_LUT_Cal(i,(1:16)+16*(j-1));
        pause(.5)
        xx.RAS_dev.Acquire_Trace(100);
        while ~xx.RAS_dev.AI_Task.complete
        end
        mdata = mean(reshape(xx.RAS_dev.PD_Channel.data, [3000, 100]), 2);
        plt.YData = mdata;
        plt2.XData = target_indices;
        plt2.YData = mdata(target_indices);
        LUTMat(j, i+1, :) = mdata;
        sumdata(j, i+1) = mean(mdata(target_indices));
        std_data(j, i+1) = std(mdata(target_indices));
        i
        toc
    end
end

%%
