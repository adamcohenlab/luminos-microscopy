classdef Stepper_TCube < Motion_Controller
    % This class is intended to control TCube devices from Thorlabs. It
    % requires the host computer to possess the dlls for the Kinesis
    % library from thorlabs, which are available from the Thorlabs website.
    % Install them to the default location and the class will find the
    % necessary drivers automatically.
    properties (Constant, Transient)
        % path to DLL files (edit as appropriate)
        MOTORPATHDEFAULT = 'C:\Program Files\Thorlabs\Kinesis\'
        % DLL files to be loaded
        DEVICEMANAGERDLL = 'Thorlabs.MotionControl.DeviceManagerCLI.dll'; %ok
        DEVICEMANAGERCLASSNAME = 'Thorlabs.MotionControl.DeviceManagerCLI.DeviceManagerCLI'; %ok
        GENERICMOTORDLL = 'Thorlabs.MotionControl.GenericMotorCLI.dll'; %ok
        GENERICMOTORCLASSNAME = 'Thorlabs.MotionControl.GenericMotorCLI.GenericMotorCLI'; %ok
        STEPPERDLL = 'Thorlabs.MotionControl.TCube.StepperMotorCLI.dll'; 
        STEPPERCLASSNAME = 'Thorlabs.MotionControl.TCube.StepperMotor.StepperMotor'; 
        CONTROL_PARAMS = 'Thorlabs.MotionControl.GenericMotorCLI.ControlParameters'; 
        ADVANCED_MOTOR = 'Thorlabs.MotionControl.GenericMotorCLI.AdvancedMotor'; 
        MOTOR_SETTINGS = 'Thorlabs.MotionControl.GenericMotorCLI.Settings'; 
        C_DLL_ONE = 'ThorLabs.MotionControl.TCube.StepperMotor.dll' 
        C_DLL_TWO = 'ThorLabs.MotionControl.DeviceManager.dll'
        % Default intitial parameters
        DEFAULTVEL = 10; % Default velocity
        DEFAULTACC = 10; % Default acceleration
        TPOLLING = 250; % Default polling time
        TIMEOUTSETTINGS = 7000; % Default timeout time for settings change
        TIMEOUTMOVE = 100000; % Default time out time for motor move
    end
    properties
        % These properties are within Matlab wrapper
        isconnected = false; % Flag set if device connected
        serialnumber; % Device serial number
        controllername; % Controller Name
        controllerdescription % Controller Description
        stagename; % Stage Name
        position; % Position
        acceleration; % Acceleration
        maxvelocity; % Maximum velocity limit
        minvelocity; % Minimum velocity limit
    end
    properties (Transient)
        % These are properties within the .NET environment.
        deviceNET; % Device object within .NET
        motorSettingsNET; % motorSettings within .NET
        deviceInfoNET; % deviceInfo within .NET
        motorconfigurationNET;
    end
    methods
        function obj = Stepper_TCube(Initializer, options) % Instantiate motor object
            arguments
                Initializer;
                options.serialnumber = '';
                options.start_position = 0;
            end
            obj@Motion_Controller(Initializer);
            if ~isempty(Initializer)
                obj.serialnumber = obj.Initializer.serialnumber; % Changed this from serial_number to match Initalizer params - DI
            else
                obj.serialnumber = options.serialnumber;
            end
            obj.loaddlls; % Load DLLs (if not already loaded)
            obj.connect();
            %obj.home(); % Don't home on FF, motor not set up for that.
            if options.start_position ~= 0
                obj.moveto(options.start_position);
            end
        end
        
        function delete(obj)
            obj.disconnect();
        end
        
        function connect(obj) % Connect device
            snumberlist = obj.listdevices();
            if ~ismember(obj.serialnumber, snumberlist)
                error("Requested serialnumber not found in devicelist.");
            end
            obj.deviceNET = Thorlabs.MotionControl.TCube.StepperMotorCLI.TCubeStepper.CreateTCubeStepper(obj.serialnumber);
            %            obj.deviceNET = Thorlabs.MotionControl.TCube.DCServoCLI.TCubeDCServo.CreateTCubeDCServo(obj.serialnumber);
            obj.deviceNET.ClearDeviceExceptions(); % Clear device exceptions via .NET interface
            obj.deviceNET.Connect(obj.serialnumber); % Connect to device via .NET interface
            n = 0;
            while ~obj.deviceNET.IsSettingsInitialized()
                if n == 5
                    error('T-Cube device setting initialization failed')
                end
                pause(1)
                n = n + 1;
            end
            
            obj.deviceNET.StartPolling(obj.TPOLLING);
            obj.deviceNET.EnableDevice();
            obj.motorconfigurationNET = obj.deviceNET.LoadMotorConfiguration(obj.serialnumber);
            obj.deviceInfoNET = obj.deviceNET.GetDeviceInfo();
        end
        function disconnect(obj) % Disconnect device
            obj.isconnected = obj.deviceNET.IsConnected(); % Update isconnected flag via .NET interface
            if obj.isconnected
                try
                    obj.deviceNET.StopPolling(); % Stop polling device via .NET interface
                    obj.deviceNET.Disconnect(); % Disconnect device via .NET interface
                catch
                    error(['Unable to disconnect device', obj.serialnumber]);
                end
                obj.isconnected = false; % Update internal flag to say device is no longer connected
            else % Cannot disconnect because device not connected
                error('Device not connected.')
            end
        end
        function reset(obj) % Reset device
            obj.deviceNET.ClearDeviceExceptions(); % Clear exceptions vua .NET interface
            obj.deviceNET.ResetConnection(obj.serialnumber) % Reset connection via .NET interface
        end
        function home(obj) % Home device (must be done before any device move
            workDone = obj.deviceNET.InitializeWaitHandler(); % Initialise Waithandler for timeout
            obj.deviceNET.Home(workDone); % Home devce via .NET interface
            obj.deviceNET.Wait(obj.TIMEOUTMOVE); % Wait for move to finish
            updatestatus(obj); % Update status variables from device
        end
        function moveto(obj, position) % Move to absolute position
            try
                workDone = obj.deviceNET.InitializeWaitHandler(); % Initialise Waithandler for timeout
                obj.deviceNET.MoveTo(position, workDone); % Move devce to position via .NET interface
                obj.deviceNET.Wait(obj.TIMEOUTMOVE); % Wait for move to finish
                updatestatus(obj); % Update status variables from device
            catch % Device faile to move
                error(['Unable to Move device ', obj.serialnumber, ' to ', num2str(position)]);
            end
        end
        function moverel_deviceunit(obj, noclicks) % Move relative by a number of device clicks (noclicks)
            if noclicks < 0 % if noclicks is negative, move device in backwards direction
                motordirection = Thorlabs.MotionControl.GenericMotorCLI.MotorDirection.Backward;
                noclicks = abs(noclicks);
            else % if noclicks is positive, move device in forwards direction
                motordirection = Thorlabs.MotionControl.GenericMotorCLI.MotorDirection.Forward;
            end % Perform relative device move via .NET interface
            obj.deviceNET.MoveRelative_DeviceUnit(motordirection, noclicks, obj.TIMEOUTMOVE);
            updatestatus(obj); % Update status variables from device
        end
        function movecont(obj, varargin) % Set motor to move continuously
            if (nargin > 1) && (varargin{1}) % if parameter given (e.g. 1) move backwards
                motordirection = Thorlabs.MotionControl.GenericMotorCLI.MotorDirection.Backward;
            else % if no parametr given move forwards
                motordirection = Thorlabs.MotionControl.GenericMotorCLI.MotorDirection.Forward;
            end
            obj.deviceNET.MoveContinuous(motordirection); % Set motor into continous move via .NET interface
            updatestatus(obj); % Update status variables from device
        end
        function stop(obj) % Stop the motor moving (needed if set motor to continous)
            obj.deviceNET.Stop(obj.TIMEOUTMOVE); % Stop motor movement via.NET interface
            updatestatus(obj); % Update status variables from device
        end
        function updatestatus(obj) % Update recorded device parameters in matlab by reading them from the devuce
            obj.isconnected = logical(obj.deviceNET.IsConnected()); % update isconncted flag
            obj.serialnumber = char(obj.deviceNET.DeviceID); % update serial number
            obj.controllername = char(obj.deviceInfoNET.Name); % update controleller name
            obj.controllerdescription = char(obj.deviceInfoNET.Description); % update controller description
            velocityparams = obj.deviceNET.GetVelocityParams(); % update velocity parameter
            obj.acceleration = System.Decimal.ToDouble(velocityparams.Acceleration); % update acceleration parameter
            obj.maxvelocity = System.Decimal.ToDouble(velocityparams.MaxVelocity); % update max velocit parameter
            obj.minvelocity = System.Decimal.ToDouble(velocityparams.MinVelocity); % update Min velocity parameter
            obj.position = System.Decimal.ToDouble(obj.deviceNET.Position); % Read current device position
        end
        function setvelocity(obj, varargin) % Set velocity and acceleration parameters
            velpars = obj.deviceNET.GetVelocityParams(); % Get existing velocity and acceleration parameters
            switch (nargin)
                case 1 % If no parameters specified, set both velocity and acceleration to default values
                    velpars.MaxVelocity = obj.DEFAULTVEL;
                    velpars.Acceleration = obj.DEFAULTACC;
                case 2 % If just one parameter, set the velocity
                    velpars.MaxVelocity = varargin{1};
                case 3 % If two parameters, set both velocitu and acceleration
                    velpars.MaxVelocity = varargin{1}; % Set velocity parameter via .NET interface
                    velpars.Acceleration = varargin{2}; % Set acceleration parameter via .NET interface
            end
            if System.Decimal.ToDouble(velpars.MaxVelocity) > 25 % Allow velocity to be outside range, but issue warning
                warning('Velocity >25 deg/sec outside specification')
            end
            if System.Decimal.ToDouble(velpars.Acceleration) > 25 % Allow acceleration to be outside range, but issue warning
                warning('Acceleration >25 deg/sec2 outside specification')
            end
            obj.deviceNET.SetVelocityParams(velpars); % Set velocity and acceleration paraneters via .NET interface
            updatestatus(obj); % Update status variables from device
        end
        function loaddlls(obj) % Load DLLs
            try % Load in DLLs if not already loaded
                NET.addAssembly([obj.MOTORPATHDEFAULT, obj.DEVICEMANAGERDLL]);
                NET.addAssembly([obj.MOTORPATHDEFAULT, obj.GENERICMOTORDLL]);
                NET.addAssembly([obj.MOTORPATHDEFAULT, obj.STEPPERDLL]);
            catch % DLLs did not load
                error('Unable to load .NET assemblies')
            end
        end
        
    end
    methods (Static)
        function serialNumbers = listdevices() % Read a list of serial number of connected devices
            Thorlabs.MotionControl.DeviceManagerCLI.DeviceManagerCLI.BuildDeviceList(); % Build device list
            serialNumbersNet = Thorlabs.MotionControl.DeviceManagerCLI.DeviceManagerCLI.GetDeviceList(); % Get device list
            serialNumbers = cell(ToArray(serialNumbersNet)); % Convert serial numbers to cell array
        end
        
    end
end
