% Copyright 2016-2017 Vicente Parot
% 
% Permission is hereby granted, free of charge, to any person obtaining a
% copy of this software and associated documentation files (the
% "Software"), to deal in the Software without restriction, including
% without limitation the rights to use, copy, modify, merge, publish,
% distribute, sublicense, and/or sell copies of the Software, and to permit
% persons to whom the Software is furnished to do so, subject to the
% following conditions:      
% 
% The above copyright notice and this permission notice shall be included
% in all copies or substantial portions of the Software.    
% 
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
% OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
% MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
% NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
% DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
% OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
% USE OR OTHER DEALINGS IN THE SOFTWARE.      
%
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
    active_cols = 768;  %256;
    active_row_offset = 0;  % 448
    active_col_offset = 0;  %275; % 320
    if isempty(active_row_offset) || active_row_offset < 0
        active_row_offset = floor((device_rows-active_rows)/2);
    end
    if isempty(active_col_offset) || active_col_offset < 0
        active_col_offset = floor((device_cols-active_cols)/2);
    end
    active_rows = min(active_rows,device_rows-active_row_offset);
    active_cols = min(active_cols,device_cols-active_col_offset);
end