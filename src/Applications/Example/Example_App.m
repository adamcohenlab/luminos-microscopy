classdef Example_App < Rig_Control_App
    methods
        function app = Example_App(varargin)
            app = app@Rig_Control_App('Example', varargin{:});
        end
    end
end
