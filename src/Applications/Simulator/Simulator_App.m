classdef Simulator_App < Rig_Control_App
    methods
        function app = Simulator_App(varargin)
            app = app@Rig_Control_App('Simulator', varargin{:});
        end
    end
end
