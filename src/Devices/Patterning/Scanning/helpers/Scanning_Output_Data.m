classdef Scanning_Output_Data < handle
    properties
        type
        galvofbx(:, :)
        galvofby(:, :)
        galvoy_wfm(:, :)
        galvox_wfm(:, :)
        PMT(:, :)
        stage_position(3, :)
    end

    methods
        function obj = Scanning_Output_Data()
        end
        function Append_Data(obj, PMT, galvofbx, galvofby, stage_position)
            obj.PMT(:, end+1) = PMT(:);
            obj.galvofbx(:, end+1) = galvofbx(:);
            obj.galvofby(:, end+1) = galvofby(:);
            obj.stage_position(:, end+1) = stage_position;
        end
    end
end
