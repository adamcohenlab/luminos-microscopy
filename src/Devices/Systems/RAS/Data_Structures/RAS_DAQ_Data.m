classdef RAS_DAQ_Data < handle
    properties
        PD_Data
        PMT_Data
        galvo_fb
        PD_Raw_Data
        PMT_Raw_Data
        galvo_fb_raw
        drive_waveform
        SLM_row_indices
    end

    methods
        function obj = RAS_DAQ_Data(PMT_Data, PD_Data, galvo_fb, drive_waveform)
            obj.PMT_Raw_Data = PMT_Data;
            obj.PD_Raw_Data = PD_Data;
            obj.galvo_fb_raw = galvo_fb;
            obj.drive_waveform = drive_waveform;
            tiled_indices = obj.expand_indices();
            obj.PMT_Data = obj.PMT_Raw_Data(tiled_indices+1);
            obj.PMT_Data = reshape(obj.PMT_Data, [numel(slm_indices), numel(tiled_indices) / numel(slm_indices)]);
            obj.PD_Data = obj.PD_Raw_Data(tiled_indices) - (obj.PD_Raw_Data(tiled_indices+1) + obj.PD_Raw_Data(tiled_indices-1)) / 2;
            obj.PD_Data = reshape(obj.PD_Data, [numel(slm_indices), numel(tiled_indices) / numel(slm_indices)]);
        end

        function PD_mean = PD_trace_mean(obj)
            PD_mean = mean(obj.PD_Data);
        end

        function Normalize_PMT_Data(obj)
            p = polyfit(obj.PD_Data, obj.PMT_Data, 2);
        end

        function tiled_indices = expand_indices(obj)
            numcycles = round(numel(obj.PD_Data)/numel(obj.drive_waveform));
            tiled_indices = repmat(obj.SLM_row_indices, [1, numcycles]);
        end
    end

end
