classdef alpdevice < handle & alpconstants
    %alpdevice ALP device

    % properties
    properties (SetAccess = protected)
        api; % ALPAPI object to access the API
        deviceid; % Device ID, set once device is allocated
        sequences; % array of alpsequence objects that are allocated in the device
        width; % mirror width in pixels
        height; % mirror height in pixels
    end

    properties (SetAccess = protected, GetAccess = protected)
    end

    % methods
    methods
        % constructor
        function obj = alpdevice(api)
            obj.api = api;
            obj.deviceid = [];

            % set sequences to empty array of alpsequences
            obj.sequences = alpsequence.empty();

            % set default height and width
            obj.height = 1024;
            obj.width = 768;
        end

        % destructor
        function delete(obj)
            obj.cleanup();
            obj.free();
            obj.deviceid = [];
        end

    end

end
