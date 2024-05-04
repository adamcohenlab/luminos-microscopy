classdef Example_Multi_Camera_App < Rig_Control_App
    properties (Transient)
        camtrigger
        camclock
        experimentfolder
        pool
    end
    methods
        function app = Example_Multi_Camera_App(varargin)
            app = app@Rig_Control_App('Example_Multi_Camera_App', varargin{:}, 'Experiment', 'Optopatch');
        end
    end
end