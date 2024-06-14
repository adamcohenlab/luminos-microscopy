function Device = Standalone_Device(rigname, devtype, subindex)
% Use subindex (default 1) to select among devices of the same type.
if nargin < 3
    subindex = 1;
end
Rig_Init = load_init(strcat(rigname, '.json'));
devtype_class = meta.class.fromName(devtype);
if isempty(devtype_class)
    error("Invalid device type");
end
index = arrayfun(@(x) meta.class.fromName(x) <= meta.class.fromName(devtype), [Rig_Init.devices.deviceType]);
Initializer = Rig_Init.devices(index);
Device = Initializer(subindex).Construct_Device();
Device.standalone_mode = true;
% logfile = fullfile(Rig_Init.dataDirectory, 'logfile.txt');
% if exist(logfile, 'file') == 2
%     fid = fopen(logfile, 'at');
% else
%     fid = fopen(logfile, 'wt');
% end
% fprintf(fid, strcat(class(Device), " ", 'opened in standalone mode... ', datestr(now, 'YYYYmmdd - HH:MM:SS'), '\n'));
% fclose(fid);
end
