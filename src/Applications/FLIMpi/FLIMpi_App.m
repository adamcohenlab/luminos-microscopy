classdef FLIMpi_App < Rig_Control_App
    methods
        function app = FLIMpi_App(varargin)
            app = app@Rig_Control_App('FLIMpi', varargin{:},'Experiment','optopatch');
        end
    end
end
