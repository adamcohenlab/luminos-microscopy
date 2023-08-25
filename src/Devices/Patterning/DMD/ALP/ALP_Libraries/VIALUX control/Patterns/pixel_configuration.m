function [device_rows, device_cols, active_rows, active_cols, ...
    active_row_offset, active_col_offset] = pixel_configuration

%% pixel_configuration
%  loads the DMD resolution and provides options to hardcode a ROI for the
%  DMD operation. by calling this function from other codes that generate
%  patterns, they can set the regions out of the ROI to always off. In
%  practice this function is being used to get the DMD resolution only.
%
% 2016 Vicente Parot
% Cohen Lab - Harvard University

%% pixel configuration
% note these are rows in the matlab matrix, but correspond to columns in
% the ALP high speed API 4.2 description. the ordinal organization is the
% same for both: a stream of numbers fills first a column and then the next
% in matlab, and first a row and then the next in ALP.
device_rows = 1024;
device_cols = 768;
active_rows = 1024; %512;
active_cols = 768; %256;
active_row_offset = 0; % 448
active_col_offset = 0; %275; % 320
if isempty(active_row_offset) || active_row_offset < 0
    active_row_offset = floor((device_rows - active_rows)/2);
end
if isempty(active_col_offset) || active_col_offset < 0
    active_col_offset = floor((device_cols - active_cols)/2);
end
active_rows = min(active_rows, device_rows-active_row_offset);
active_cols = min(active_cols, device_cols-active_col_offset);
end