classdef (Abstract) Device < handle & matlab.mixin.SetGetExactNames & matlab.mixin.Heterogeneous
    properties (Transient)
        % A Device_Initializer object that specifies values for a subset of properties of the virtual device which should be initialized on device construction. This property is transient, so it will not be saved during a call to Build_Archive.
        Initializer Device_Initializer

        % standalone_mode is set to true if the device is called from the Standalone_Device utility function. Otherwise it is kept at false, which is the default value.
        standalone_mode = false;

        daq_waveform_control = false;
        is_remote = false;
        port_timeout = 5; %Seconds timeout to wait for serial read and write.
    end
    properties
        % Optional name for the device. This is strongly recommended if there are multiple devices of a given type attached to a single Rig. Otherwise, you'll have no way of discriminating which is which in the [Rig_Control_App](../Applications/Rig_Control_App_DG.md) Devices array.
        name string
    end
    events
        exp_finished % This event can be monitored from the Rig_Control_App. Set your device to trigger this event when it finishes an experiment and needs to save an archive.
    end
    methods
        % The constructor for the virtual device takes as an input either a Device_Initializer or an Initializer_Storage object. If the input is an Initializer_Storage object, the constructor first searches the structure for the correct initializer type. If multiple devices of a given type are in the Initializer_Storage object. The optional name argument is used to specify which initializer corresponds to this device.
        % * Initializers: Device_Initializer object or Initializer_Storage object. Values from the initializer will be loaded into the constructed device.
        % * *name:* Optional name argument for situations where multiple devices of a given type are present in the structure.
        function obj = Device(Initializers, options)
            arguments
                Initializers = []; %Needs to be able to handle 0-argument construction for creation of empty array placeholders.
                options.name = [];
            end
            % load initializer
            if isempty(Initializers)
                return
            end
            if isa(Initializers, 'Initializer_Storage')
                obj.Initializer = obj.Extract_Init(Initializers, class(obj), options.name);
            elseif isa(Initializers, [class(obj), '_Initializer'])
                obj.Initializer = Initializers;
            else
                error(['Initializer for', ' ', class(obj), ' not correctly loaded']);
            end
            obj.Copy_Initializer_Data();
        end
        function Wait_Until_Done(obj)
            %Defines an empty function as a default. Can be implemented in
            %subclasses to allow the device to block the end of an
            %application even if it is not the master.
        end
    end

    methods (Sealed)
        % This method takes all non-Transient properties from the device and copies them into a structure with field names corresponding to device properties. deviceType and Device_Name are added to the structure manually. This method is called by the Application_Layer when experimental data is saved.
        function Archive = Build_Archive(obj)
            mc = metaclass(obj);
            proplist = mc.PropertyList;
            props2save = findobj(proplist, 'Transient', false);
            names = {props2save.Name};
            Archive = cell2struct(get(obj, names), names, 2);
            Archive.deviceType = class(obj);
            Archive.Device_Name = obj.name;
        end

        % This method copies all of the property values from a Device_Initializer object into the corresponding properties of the Device, obj.
        function Copy_Initializer_Data(obj)
            proplist = properties(obj.Initializer);
            proplist = proplist(~(strcmp(proplist, 'Prop_Allowed_Vals') | strcmp(proplist, 'deviceType')));
            for i = 1:numel(proplist)
                propValue = get(obj.Initializer, proplist{i});

                % cast strings to char arrays
                if isstring(propValue)
                    propValue = char(propValue);
                end

                set(obj, proplist{i}, propValue);
            end
        end
    end

    methods (Static)
        % This static method scans an Initializer_Storage object and returns the Device_Initializer object whose device type is equal to devtype. If multiple initializers with a device type equal to devtype are present in the structure, the method returns the Device_Initializer whose name property matches the name input to the function.
        % * Initializers: Initializer_Storage object to search for the Device_Initializer.
        % * devtype: The device type (class) of the virtual device to be initialized.
        % * name: The name of the virtual device to be initialized.
        function Initializer = Extract_Init(Initializers, devtype, name)
            init_index = strcmp(devtype, [Initializers.devices.deviceType]);
            if sum(init_index(:)) == 1
                Initializer = Initializers.devices(init_index);
            else
                named_index = strcmp([devtype, '_Initializer'], {Initializers.devices.deviceType}) & strcmp(name, {Initializers.devices.name});
                Initializer = Initializers.devices(named_index);
            end
        end
    end
end
