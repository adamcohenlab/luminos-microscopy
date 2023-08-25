function [mov, avgImg, Device_Data] = Extract_Mov(path, options)
arguments
    path
    options.dark_offset = 0;
    options.dark_frame_included = false;
    options.return_uint16 = false;
    options.use_tiff = false;
    options.cam_indices = [];
    options.unpack_singleton = true; % this function will output a single movie and average image if this is true. Change to false to get an iterable structure consistent with multi-cam movies.
end
metadata = load(fullfile(path, 'output_data.mat'));
Device_Data = metadata.Device_Data;

% Leaving this the same as before
cam = Extract_Device_Archive(Device_Data, 'Camera');

% Optional manual selection of camera indices
if isempty(options.cam_indices)
    cam_indices = 1:numel(cam);
else
    cam_indices = options.cam_indices;
end

%     if numel(cam)>1
mov = cell(1, numel(cam_indices)); %Initialize movie superstructure
avgImg = cell(1, numel(cam_indices)); %Initialize movie superstructure
%     end

for ii = cam_indices
    ncol = cam(ii).ROI(2);
    nrow = cam(ii).ROI(4);

    bin = cam(ii).bin;

    if ~options.use_tiff
        fname2 = sprintf('frames%d.bin', ii); %Default name (valid for latest RigControl releases)
    else
        disp("Using TIFF file for movie input.");
        fname2 = sprintf('frames%d.tiff', ii); %Default name (valid for latest RigControl releases)
    end

    bin_file = fullfile(path, fname2);
    if ~options.use_tiff
        if ~exist(bin_file, "file")
            bin_file = fullfile(path, 'frames.bin'); %Name used in former releases
        end
    end
    if ~exist(bin_file, "file") %Otherwise, use first .bin file seen in directory.
        warning("No file named 'frames1.bin' or 'frames.bin' found in directory. Will try to read first *.bin file found.")
        if ~options.use_tiff
            bin_files_listing = dir(fullfile(path, "*.bin"));
        else
            bin_files_listing = dir(fullfile(path, "*tif*"));
        end
        bin_file = fullfile(path, bin_files_listing(1).name);
    end
    if ~exist(bin_file, "file")
        error("No binary movie file found in current directory");
    end

    bin_file
    if ~options.use_tiff
        [mov{ii}, ~] = readBinMov(bin_file, nrow, ncol);
    else
        info = imfinfo(bin_file);
        N_pages = numel(info);
        mov{ii} = zeros(nrow, ncol, N_pages);
        for k = 1:N_pages
            mov{ii}(:, :, k) = imread(bin_file, k, 'Info', info);
        end
    end
    if ~options.return_uint16
        if options.dark_frame_included
            mov{ii} = single(mov{ii}-min(mov{ii}, [], 3));
        else
            mov{ii} = single(mov{ii}) - options.dark_offset;
        end
    end
    avgImg{ii} = double(mean(mov{ii}, 3));
end

if numel(mov) == 1 && options.unpack_singleton
    mov = mov{1};
    avgImg = avgImg{1};
end

end