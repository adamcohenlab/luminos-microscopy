classdef alpsequence < handle & alpconstants
    %alpsequence ALP sequence

    % properties
    properties (SetAccess = protected)
        device; % ALP DEVICE the sequence is connected to
        sequenceid; % Sequence ID, set once sequence is allocated
        width; % mirror width in pixels
        height; % mirror height in pixels
    end

    properties (SetAccess = protected, GetAccess = protected)
    end

    % methods
    methods
        % constructor
        function obj = alpsequence(device)
            obj.device = device;
            obj.sequenceid = [];
            obj.device.registersequence(obj);
            obj.height = device.height;
            obj.width = device.width;
        end

        % destructor
        function delete(obj)
            obj.device.unregistersequence(obj);
            obj.free();
            obj.sequenceid = [];
        end

    end

end
