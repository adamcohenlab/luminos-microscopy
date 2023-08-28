classdef Simulator_App < Rig_Control_App
    properties (Transient)
        tabs cell
    end
    methods
        function app = Simulator_App(varargin)
            app = app@Rig_Control_App('Simulator', varargin{:});
            app.tabs = {'Main', 'Waveforms'}; % for javascript
        end
    end
end
