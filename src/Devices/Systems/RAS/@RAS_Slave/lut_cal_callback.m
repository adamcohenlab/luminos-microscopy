function obj = lut_cal_callback(obj, src, chan_data)
%obj.data_plt.YData=obj.PD_Channel.data(:);
drawnow
pause(.1)
namelist = {chan_data.name};
pd_chan = chan_data(find(strcmp([namelist{:}], 'pd_channel')));
obj.LUT_Data.Append_Mean_Trace(obj.wavelength, obj.gval, mean(pd_chan.data(:)));
obj.ready = true;
end