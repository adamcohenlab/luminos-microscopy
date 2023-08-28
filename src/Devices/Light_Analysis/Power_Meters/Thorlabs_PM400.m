classdef Thorlabs_PM400 < Device & matlab.mixin.Copyable
    %Thorlabs_PM400 Matlab class to control Thorlabs power meters
    % From Matlab File Exchange: https://www.mathworks.com/matlabcentral/fileexchange/92803-matlab-driver-for-thorlabs-power-meter
    %   Driver for Thorlabs power meter
    %   It is a 'wrapper' to control Thorlabs devices via the Thorlabs .NET
    %   DLLs.
    %
    %   User Instructions:
    %   1. Download the Optical Power Monitor from the Thorlabs website:
    %   https://www.thorlabs.com/software_pages/ViewSoftwarePage.cfm?Code=OPM
    %   2. Read the manual in the installation folder or the sofware help page
    %   https://www.thorlabs.com/software/MUC/OPM/v3.0/TL_OPM_V3.0_web-secured.pdf
    %   3. Following the instructions in section 9: Write Your Own Application
    %   4. This scripts need only the .net wrapper dll so follow the instruction for C#
    %   5. Edit MOTORPATHDEFAULT below to point to the location of the DLLs
    %   6. Connect your Power Meter with sensor to the PC USB port and power
    %      it on.
    %
    %   For developers:
    %   The definition for all the classes can be found in the C sharp exmple
    %   provided by Thorlab. (Shipped together with the software.)
    %
    %   Example:
    %   clear
    %   meter=Thorlabs_PM400(Initializer);            % Initiate the object
    %   DeviceDescription=meter.listdevices; % List available device(s)
    %   meter = meter.connect(DeviceDescription);    % Connect selected device
    %   meter.setWaveLength(780);            % Set sensor wavelength
    %   meter.setDispBrightness(0.5);        % Set display brightness
    %   meter.setAttenuation(0);             % Set Attenuation
    %   meter.sensorInfo;                    % Retrive the sensor info
    %   meter.darkAdjust;                    % (PM400 ONLY)
    %   meter.getDarkOffset;                 % (PM400 ONLY)
    %   meter.updateReading;                 % Update the reading
    %   meter.disconnect;                    % Disconnect and release
    %
    %   Author: Zimo Zhao
    %   Dept. Engineering Science, University of Oxford, Oxford OX1 3PJ, UK
    %   Email: zimo.zhao@emg.ox.ac.uk (please email issues and bugs)
    %   Website: https://eng.ox.ac.uk/smp/
    %
    %   Known Issues:
    %   1. This program is not yet suitable for multiple power meters
    %   connection.
    %   2. More functions to be added in the future.
    %
    %   Version History:
    %   1.00 ----- 21 May 2021 ----- Initial Release
    %   1.01 ----- 17 Aug 2021 ----- Clarify the way of utilizing *.dll files

    properties (Constant, Hidden)
        % Path to .net *.dll files (edit as appropriate)
        % pwd --- Current working directory of this file
        % (depending on the location where you put this file)
        % This line points to folder 'Thorlabs_DotNet_dll' under the same directory
        METERPATHDEFAULT = fullfile(fileparts(mfilename('fullpath')), '\Thorlabs_Libraries\');
        % Comment out this line and uncomment next line to use customized dll file directory
        %METERPATHDEFAULT=['C:\Updated_Control_Software\2020RigControl\src\Devices\Light_Analysis\Power_Meters\Thorlabs_Libraries\'];
        % *.dll files to be loaded
        TLPMDLL = 'Thorlabs.TLPM_64.Interop.dll';
        TLPMCLASSNAME = 'Thorlabs.TLPM_64.Interop.TLPM';
    end

    properties
        % These properties are within Matlab wrapper
        isConnected = false; % Flag set if device connected
        resourceName; % USB resource name
        resourceNameConnected; % USB resource name
        modelName; % Power meter model name
        serialNumber; % Power meter serial number
        Manufacturer; % Power meter manufacturer
        DeviceAvailable; % Power meter avaliablity
        numberOfResourceName; % Number of available resources
        sensorName; % Sensor name
        sensorSerialNumber; % Sensor serial number
        sensorCalibrationMessage; % Sensor calibration information
        sensorType; % Sensor type
        sensorSubType; % Sensor subtype
        sensorFlags; % Sensor flag
        DarkOffset_Voltage; % (PM400 ONLY) Dark offset voltage
        DarkOffset_Voltage_Unit; % (PM400 ONLY) Dark offset voltage unit
        meterPowerReading; % Power reading
        meterPowerUnit; % Power reading unit
        meterVoltageReading; % Voltage reading
        meterVoltageUnit; % Voltage reading unit
        autoconnect
    end

    properties (Transient) %(Hidden)
        % These are properties within the .NET environment.
        deviceNET; % Device object within .NET
    end

    methods
        function obj = Thorlabs_PM400(Initializer)
            %Thorlabs_PM400 Construct an instance of this class
            %   This function first loads the dlls from the path and then
            %   list all the device available. It will return a list of all
            %   the available device(s).
            obj@Device(Initializer);
            if obj.autoconnect == 1 || isempty(obj.autoconnect)
                obj.connect()
            end
        end

        function delete(obj)
            %DELETE Deconstruct the instance of this class
            %   Usage: obj.delete;
            %   This function disconnects the device and exits.
            if obj.isConnected
                try
                    warning('Program Terminated with Device Connected.');
                    obj.disconnect;
                catch
                    warning('Failed to release the device.');
                end
            else % Cannot disconnect because device is not connected
                %fprintf('Device Released Properly.\r\r');
            end

        end

        function obj = connect(obj, options)
            %CONNECT Connect to the specified resource.
            %   Usage: obj.connect(resource);
            %   By default, it will connect to the first resource on the
            %   list [resource_index=1] with ID query [ID_Query=1] and
            %   reset [Reset_Device=1];
            %   Use
            %   obj.connect(resource,ID_Query,Reset_Device,resource_index)
            %   to modify the default values.
            arguments
                obj
                options.resource = obj.listdevices;
                options.resource_index(1, 1) {mustBeNumeric} = 1 % (default) First resource
                options.ID_Query(1, 1) {mustBeNumeric} = 1 % (default) Query the ID
                options.Reset_Device(1, 1) {mustBeNumeric} = 1 % (default) Reset
            end
            Reset_Device = options.Reset_Device;
            ID_Query = options.ID_Query;
            resource_index = options.resource_index;
            resource = options.resource;
            obj.loaddlls;
            [obj.resourceName, obj.modelName, obj.serialNumber, obj.Manufacturer, obj.DeviceAvailable] = obj.listdevices;
            if isempty(obj.resourceName)
                obj.isConnected = false;
                warning('No Resource is found, please check the connection.');
            else
                obj.numberOfResourceName = size(obj.resourceName, 1);
                fprintf('Found the following %d device(s):\r', obj.numberOfResourceName);
                for i = 1:1:size(obj.resourceName, 1)
                    fprintf('\t\t%d) %s\r', i, obj.resourceName(i, :));
                end
                fprintf('Use <Your_Meter_List>.connect(resourceName) to connect a single/the first device.\r');
                fprintf('or\r');
                fprintf('Use <Your_Meter_List>.connect(resourceName,index) to connect multiple devices.\r\r');
            end

            if ~obj.isConnected && obj.DeviceAvailable(resource_index)
                % The core method to create the power meter instance
                obj.deviceNET = Thorlabs.TLPM_64.Interop.TLPM(resource(resource_index, :), logical(ID_Query), logical(Reset_Device));
                fprintf('Successfully connect the device:\r\t\t%s\r', resource(resource_index, :));
                obj.resourceNameConnected = resource(resource_index, :);
                obj.isConnected = true;
                obj.modelName = obj.modelName{resource_index};
                obj.serialNumber = obj.serialNumber(resource_index, :);
                obj.Manufacturer = obj.Manufacturer(resource_index, :);
                %obj.DeviceAvailable(resource_index)=0;
                %obj.isConnected=false;
                %obj.deviceNET=obj_copy.deviceNET;
                %obj.resourceNameConnected=resource(resource_index,:);
                %obj.modelName=obj_copy.modelName;
                %obj.serialNumber=obj_copy.serialNumber;
                %obj.Manufacturer=obj_copy.Manufacturer;
            else
                warning('Device is already connected.');
            end
        end

        function disconnect(obj)
            %DISCONNECT Disconnect the specified resource.
            %   Usage: obj.disconnect;
            %   Disconnect the specified resource.
            if obj.isConnected
                fprintf('\tDisconnecting ... %s\r', obj.resourceNameConnected);
                try
                    obj.deviceNET.Dispose(); %Disconnect the device
                    obj.isConnected = false;
                    fprintf('\tDevice Released Properly.\r\r');
                catch
                    warning('Unable to disconnect device.');
                end
            else % Cannot disconnect because device not connected
                warning('Device not connected.')
            end
        end

        function setWaveLength(obj, wavelength)
            %SETWAVELENGTH Set the sensor wavelength.
            %   Usage: obj.setWaveLength(wavelength);
            %   Set the sensor wavelength. This method will check the input
            %   and force it to a vaild value if it is out of the range.
            [~, wavelength_MIN] = obj.deviceNET.getWavelength(1);
            [~, wavelength_MAX] = obj.deviceNET.getWavelength(2);
            if (wavelength_MIN <= wavelength && wavelength <= wavelength_MAX)
                obj.deviceNET.setWavelength(wavelength);
            else
                if wavelength_MIN > wavelength
                    warning('Exceed minimum wavelength! Force to the minimum.');
                    obj.deviceNET.setWavelength(wavelength_MIN);
                end
                if wavelength > wavelength_MAX
                    warning('Exceed maximum wavelength! Force to the maximum.');
                    obj.deviceNET.setWavelength(wavelength_MAX);
                end
            end
        end

        function setDispBrightness(obj, Brightness)
            %SETDISPBRIGHTNESS Set the display brightness.
            %   Usage: obj.setDispBrightness(Brightness);
            %   Set the display brightness. This method will check the input
            %   and force it to a vaild value if it is out of the range.
            if (0.0 <= Brightness && Brightness <= 1.0)
                obj.deviceNET.setDispBrightness(Brightness);
            else
                if 0.0 > Brightness
                    warning('Exceed minimum brightness! Force to the minimum.');
                    Brightness = 0.0;
                    obj.deviceNET.setDispBrightness(Brightness);
                end
                if Brightness > 1.0
                    warning('Exceed maximum brightness! Force to the maximum.');
                    Brightness = 1.0;
                    obj.deviceNET.setDispBrightness(Brightness);
                end
            end
            fprintf('Set Display Brightness to %d%%\r', Brightness*100);
        end

        function setAttenuation(obj, Attenuation)
            %SETATTENUATION Set the attenuation.
            %   Usage: obj.setAttenuation(Attenuation);
            %   Set the attenuation.
            if any(strcmp(obj.modelName, {'PM100A', 'PM100D', 'PM100USB', 'PM200', 'PM400'}))
                [~, Attenuation_MIN] = obj.deviceNET.getAttenuation(1);
                [~, Attenuation_MAX] = obj.deviceNET.getAttenuation(2);
                if (Attenuation_MIN <= Attenuation && Attenuation <= Attenuation_MAX)
                    obj.deviceNET.setAttenuation(Attenuation);
                else
                    if Attenuation_MIN > Attenuation
                        warning('Exceed minimum Attenuation! Force to the minimum.');
                        Attenuation = Attenuation_MIN;
                        obj.deviceNET.setAttenuation(Attenuation);
                    end
                    if Attenuation > Attenuation_MAX
                        warning('Exceed maximum Attenuation! Force to the maximum.');
                        Attenuation = Attenuation_MAX;
                        obj.deviceNET.setAttenuation(Attenuation);
                    end
                end
                fprintf('Set Attenuation to %.4f dB, %.4fx\r', Attenuation, 10^(Attenuation / 20));
            else
                warning('This command is not supported on %s.', obj.modelName);
            end
        end

        function sensorInfo = sensorInfo(obj)
            %SENSORINFO Retrive the sensor information.
            %   Usage: obj.sensorInfo;
            %   Read the information of sensor connected and store it in
            %   the properties of the object.
            for i = 1:1:3
                descr{i} = System.Text.StringBuilder;
                descr{i}.Capacity = 1024;
            end
            [~, type, subtype, sensor_flag] = obj.deviceNET.getSensorInfo(descr{1}, descr{2}, descr{3});
            obj.sensorName = char(descr{1}.ToString);
            obj.sensorSerialNumber = char(descr{2}.ToString);
            obj.sensorCalibrationMessage = char(descr{3}.ToString);
            switch type
                case 0x00
                    obj.sensorType = 'No sensor';
                    switch subtype
                        case 0x00
                            obj.sensorSubType = 'No sensor';
                        otherwise
                            warning('Unknown sensor.');
                    end
                case 0x01
                    obj.sensorType = 'Photodiode sensor';
                    switch subtype
                        case 0x01
                            obj.sensorSubType = 'Photodiode adapter';
                        case 0x02
                            obj.sensorSubType = 'Photodiode sensor';
                        case 0x03
                            obj.sensorSubType = 'Photodiode sensor with integrated filter identified by position';
                        case 0x12
                            obj.sensorSubType = 'Photodiode sensor with temperature sensor';
                        otherwise
                            warning('Unknown sensor.');
                    end
                case 0x02
                    obj.sensorType = 'Thermopile sensor';
                    switch subtype
                        case 0x01
                            obj.sensorSubType = 'Thermopile adapter';
                        case 0x02
                            obj.sensorSubType = 'Thermopile sensor';
                        case 0x12
                            obj.sensorSubType = 'Thermopile sensor with temperature sensor';
                        otherwise
                            warning('Unknown sensor.');
                    end
                case 0x03
                    obj.sensorType = 'Pyroelectric sensor';
                    switch subtype
                        case 0x01
                            obj.sensorSubType = 'Pyroelectric adapter';
                        case 0x02
                            obj.sensorSubType = 'Pyroelectric sensor';
                        case 0x12
                            obj.sensorSubType = 'Pyroelectric sensor with temperature sensor';
                        otherwise
                            warning('Unknown sensor.');
                    end
                otherwise
                    warning('Unknown sensor.');
            end
            tag = rem(sensor_flag, 16);
            switch tag
                case 0x0000

                case 0x0001
                    obj.sensorFlags = [obj.sensorFlags, 'Power sensor '];
                case 0x0002
                    obj.sensorFlags = [obj.sensorFlags, 'Energy sensor '];
                otherwise
                    warning('Unknown flag.');
            end
            sensor_flag = sensor_flag - tag;
            tag = rem(sensor_flag, 256);
            switch tag
                case 0x0000

                case 0x0010
                    obj.sensorFlags = [obj.sensorFlags, 'Responsivity settable '];
                case 0x0020
                    obj.sensorFlags = [obj.sensorFlags, 'Wavelength settable '];
                case 0x0040
                    obj.sensorFlags = [obj.sensorFlags, 'Time constant settable '];
                otherwise
                    warning('Unknown flag.');
            end
            sensor_flag = sensor_flag - tag;
            tag = rem(sensor_flag, 256*16);
            switch tag
                case 0x0000

                case 0x0100
                    obj.sensorFlags = [obj.sensorFlags, 'With Temperature sensor '];
                otherwise
                    warning('Unknown flag.');
            end
            sensorInfo.Type = obj.sensorType;
            sensorInfo.SubType = obj.sensorSubType;
            sensorInfo.Flags = obj.sensorFlags;
        end

        function updateReading(obj, period)
            %UPDATEREADING Update the reading from power meter.
            %   Usage: obj.updateReading;
            %   Retrive the reading from power meter and store it in the
            %   properties of the object

            [~, obj.meterPowerReading] = obj.deviceNET.measPower;
            pause(period)
            [~, meterPowerUnit_] = obj.deviceNET.getPowerUnit;
            switch meterPowerUnit_
                case 0
                    obj.meterPowerUnit = 'W';
                case 1
                    obj.meterPowerUnit = 'dBm';
                otherwise
                    warning('Unknown');
            end
            %             if any(strcmp(obj.modelName,{'PM100D', 'PM100A', 'PM100USB', 'PM160T', 'PM200', 'PM400'}))
            %                 [~,obj.meterVoltageReading]=obj.deviceNET.measVoltage;
            %                 obj.meterVoltageUnit='V';
            %             end
        end

        function darkAdjust(obj)
            %DARKADJUST (PM400 Only) Initiate the Zero value measurement.
            %   Usage: obj.darkAdjust;
            %   Start the measurement of Zero value.
            if any(strcmp(obj.modelName, 'PM400'))
                obj.deviceNET.startDarkAdjust;
                [~, DarkState] = obj.deviceNET.getDarkAdjustState;
                while DarkState
                    [~, DarkState] = obj.deviceNET.getDarkAdjustState;
                end
            else
                warning('This command is not supported on %s.', obj.modelName);
            end
        end

        function [DarkOffset_Voltage, DarkOffset_Voltage_Unit] = getDarkOffset(obj)
            %GETDARKOFFSET (PM400 Only) Read the Zero value from powermeter.
            %   Usage: [DarkOffset_Voltage,DarkOffset_Voltage_Unit]=obj.getDarkOffset;
            %   Retrive the Zero value from power meter and store it in the
            %   properties of the object
            if any(strcmp(obj.modelName, 'PM400'))
                [~, DarkOffset_Voltage] = obj.deviceNET.getDarkOffset;
                DarkOffset_Voltage_Unit = 'V';
                obj.DarkOffset_Voltage = DarkOffset_Voltage;
                obj.DarkOffset_Voltage_Unit = DarkOffset_Voltage_Unit;
            else
                warning('This command is not supported on %s.', obj.modelName);
            end
        end

    end

    methods (Static)
        function [resourceName, modelName, serialNumber, Manufacturer, DeviceAvailable] = listdevices() % Read a list of resource names
            %LISTDEVICES List available resources.
            %   Usage: obj.listdevices;
            %   Retrive all the available devices and return it back.
            Thorlabs_PM400.loaddlls; % Load DLLs
            findResource = Thorlabs.TLPM_64.Interop.TLPM(System.IntPtr); % Build device list
            [~, count] = findResource.findRsrc; % Get device list
            for i = 1:1:4
                descr{i} = System.Text.StringBuilder;
                descr{i}.Capacity = 2048;
            end
            if count > 0
                for i = 0:1:count - 1
                    findResource.getRsrcName(i, descr{1});
                    [~, Device_Available] = findResource.getRsrcInfo(i, descr{2}, descr{3}, descr{4});
                    resourceNameArray(i+1, :) = char(descr{1}.ToString);
                    modelNameArray{i+1} = char(descr{2}.ToString);
                    serialNumberArray(i+1, :) = char(descr{3}.ToString);
                    ManufacturerArray(i+1, :) = char(descr{4}.ToString);
                    DeviceAvailableArray(i+1, :) = Device_Available;
                end
                resourceName = resourceNameArray;
                modelName = modelNameArray;
                serialNumber = serialNumberArray;
                Manufacturer = ManufacturerArray;
                DeviceAvailable = DeviceAvailableArray;
            else
                resourceName = [];
                modelName = [];
                serialNumber = [];
                Manufacturer = [];
                DeviceAvailable = [];
            end
            findResource.Dispose();
        end
        function loaddlls() % Load DLLs
            %LOADDLLS Load needed dll libraries.
            %   Usage: obj.loaddlls;
            %   Change the path of dll to suit you application.
            if ~exist(Thorlabs_PM400.TLPMCLASSNAME, 'class')
                try % Load in DLLs if not already loaded
                    NET.addAssembly([Thorlabs_PM400.METERPATHDEFAULT, Thorlabs_PM400.TLPMDLL]);
                catch % DLLs did not load
                    error('Unable to load .NET assemblies')
                end
            end
        end
    end
end
