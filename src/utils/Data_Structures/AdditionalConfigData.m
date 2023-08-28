% Class for storing/retrieving additional config data from .mat files. This class is not for using the .json config files.
% We use .mat files for data that the user shouldn't edit.

classdef AdditionalConfigData < handle
    properties
        filePath string; % The path to the folder that contains the config data
        data; % The data stored in the config file
    end
    
    methods(Access = private)
        % find the path to the config file
        function setFilePath(obj, className, deviceName)
            classPath = which(className);
            parentFolderPath = fileparts(classPath);
            
            % make a .data folder inside parentFolderPath if it doesn't exist
            if ~exist(fullfile(parentFolderPath, '.data'), 'dir')
                mkdir(fullfile(parentFolderPath, '.data'));
            end
            
            % Create a valid filename
            validDeviceName = matlab.lang.makeValidName(deviceName);
            obj.filePath = fullfile(parentFolderPath, '.data', sprintf('%s_AdditionalConfigData.mat', validDeviceName));
        end
    end
    
    methods
        % Constructor
        function obj = AdditionalConfigData(device)
            arguments
                device Device;
            end
            
            className = class(device);
            deviceName = device.name;
            obj.setFilePath(className, deviceName);
            
            % load the data
            obj.load();
        end
        
        % Load the config file
        function load(obj)
            if exist(obj.filePath, 'file')
                matData = load(obj.filePath);
                obj.data = matData.data;
            else
                obj.data = struct();
            end
        end
        
        % Get a value from the config file
        function value = get(obj, key)
            if isfield(obj.data, key)
                value = obj.data.(key);
            else
                value = [];
            end
        end
        
        % Set a value in the config file
        function set(obj, key, value)
            obj.data.(key) = value;
            
            % save the data
            data = obj.data;
            save(obj.filePath, 'data');
        end
    end
end