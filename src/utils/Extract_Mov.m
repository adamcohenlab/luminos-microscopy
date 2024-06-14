% Extract_Mov - Extracts a movie from a given path and returns the movie, average image, and device data.
%
% Syntax:
%   [mov, avgImg, Device_Data] = Extract_Mov(path, options)
%
% Inputs:
%   path - A string containing the path to the movie file.
%   options - A struct containing optional parameters for the extraction process.
%
% Outputs:
%   mov - A 3D matrix containing the movie frames.
%   avgImg - A 2D matrix containing the average image of the movie.
%   Device_Data - A struct containing device-specific data.
%
% Example:
%   [mov, avgImg, Device_Data] = Extract_Mov('C:\Users\Labmember\Documents\', struct('option1', value1, 'option2', value2));
%
function [mov, avgImg, Device_Data] = Extract_Mov(path, options)
arguments
    path
    options.dark_offset = 0;
    options.dark_frame_included = false;
    options.return_uint16 = false;
    options.use_tiff = false; %allows unpacking movie from Tiff instead of .bin for adaptability to other recording formats.
    options.cam_indices = [];
    options.unpack_singleton = true; % this function will output a single movie and average image if this is true. Change to false to get an iterable structure consistent with multi-cam movies.
end
metadata = load(fullfile(path, 'output_data.mat'));
Device_Data = metadata.Device_Data;

useOldNames = isfield(Device_Data{1},'Rig');
% Leaving this the same as before
if useOldNames
    cam = Extract_Device_Archive(Device_Data, 'Cam_Controller');
else
    cam = Extract_Device_Archive(Device_Data, 'Camera');
end

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
        t = Tiff(bin_file,'r'); %Tiff.read much faster on large multipage than imread, even with imfinfo.
        N_pages = numel(info);
        mov{ii} = zeros(nrow,ncol,N_pages,'uint16');
        mov{ii}(:,:,1) = t.read();
        for k = 2:N_pages
            %mov{ii}(:,:,k) = imread(bin_file,k,'Info',info);
            t.nextDirectory();
            mov{ii}(:,:,k) = t.read();

            if ~mod(k,100)
                sprintf("%d pages read",k)
            end
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