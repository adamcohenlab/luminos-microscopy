classdef Rig_Control_App < matlab.apps.AppBase & matlab.mixin.SetGetExactNames
    properties (Transient)
        % Properties that are not saved to disk
        
        Devices = Device.empty; % Array of Device objects for virtual devices
        monitored_devices_index % Logical indexing vector for data-saving portion
        explistener % Listener object for exp_finished event
        blank_listener % Listener object for blank screen during acquisition
        Experiment % Name of the experiment type
        expfolder % Folder for storing individual experiment data
        datafile % File for saving virtual device data
        basepath % Path to the luminos repository
        datafolder % Directory for storing data by date
        server_target % Path to remote server for data copying
        Rig_Init Rig_Initializer % Rig_Initializer object
        User User_Key % User_Key object
        logfile % File for recording log data
        exp_complete = false; % Flag indicating experiment completion
        isDataAcquired = false; % Flag indicating if any data has been acquired
        blank_fig_handles = []; % Handles for figures for blank screen during acquisition
        
        jsServer JS_Server; % JS_Server object for communication with the JS frontend
        VR_On logical = false; % Flag for VR mode
        VRclient % VR client object
        wasAppDeletedFromJS = false; % Flag indicating app deletion from JS
        jsPort = 3010; % Port number for JS communication
    end
    
    properties
        % Additional properties
        gitInfo % Git information
        rigName % Name of the rig
        tabs % Which tabs to show (Main, Waveforms, DMD, etc)
    end

    properties (Transient, SetObservable)
        screen_blanked = false; % Flag indicating screen blanking status
    end

    events
        exp_finished % Event for experiment completion
    end
    
    methods
        % Constructor. Initializes properties, loads initialization data, constructs device objects, and starts jsServer.
        function app = Rig_Control_App(rigName, username, options)
            arguments
                rigName char
                username = 'Unknown username' % name of user running the app
                options.Experiment = [] % optional specification of experiment type
            end

            % clear the mex variables as a hack for some bad memory management
            clear mex
            warning('on','all');
            app.explistener = event.listener(app, 'exp_finished', @(src, evt)app.expFinishedCallback(src, evt));
            app.rigName = rigName;
            app.Experiment = options.Experiment;
            filepath = fileparts(mfilename('fullpath'));
            app.basepath = filepath(1:(strfind(filepath, '\src')));
            app.loadInitData(username);
            app.attachDevices();
            app.jsServer = JS_Server(app); % Start jsServer last to allow params from app to get passed.
        end
        
        % This is one of the most useful methods in the Application_Layer, so it gets its own section. You will quite often encounter situations where the app is in-scope, but the specific device that you want is not. Calling the getDevice(type) will search the app's Devices structure for devices that are of class type or are of a subclass of class type. It then returns all of those devices as a (possibly heterogeneous) array. If the optional name argument is specified. Only virtual devices whos name property is equal to options.name and are of class type or are of a subclass of type will be returned.
        % * type: The class of device requested. If the optional *name* argument is not specified, the method will return all devices in the Devices property of the app that are of class type or are of a subclass of class type.
        % * *name*: Optional character array or string input. If specified, the method will only return devices whos name property matches *name*.
        function device = getDevice(app, type, options)
            arguments
                app
                type
                options.name = []
                options.displayWarning = true
            end
            mc = meta.class.fromName(type);
            if isempty(mc)
                error("%s is not a valid device class name.", type); %warning and error take sprintf-like arguments directly
            end
            
            % Filter by type
            matching_indices = arrayfun(@(x)metaclass(x) <= mc, app.Devices); %To produce the logical index, I'm making use of the A<=B definition for metaclasses, which returns true if the class of A and B are the same or A is a subclass of B. I'm then using arrayfun to apply this test to every device.
            
            % Check if there is more than one matching device
            if sum(matching_indices(:)) == 0 % If matching device not found, warn, and return empty
                if options.displayWarning
                    warning("No device of type %s found.", type)
                end
                device = eval([mc.Name, '.empty()']); % TO DO: FIGURE OUT A WAY TO REMOVE THE EVAL CALL HERE
            elseif sum(matching_indices(:)) == 1 || isempty(options.name)
                device = app.Devices(matching_indices);
            else
                % Filter by name
                candidates = app.Devices(matching_indices);
                res = candidates(strcmp([candidates.name], options.name));
                if isempty(res)
                    if options.displayWarning
                        warning("No devices of type %s with name %s found.", type, options.name)
                    end
                    device = eval([mc.Name, '.empty()']); % TO DO: FIGURE OUT A WAY TO REMOVE THE EVAL CALL HERE
                    return
                end
                device = res;
            end
        end
        
        % This method creates a folder in the path specified by the datafolder property of the app (which is the folder for the day). The folder is named with the current time in HHMMSS format with a string tag appended onto the timestamp. This tag serves as a convenient way to name experiments for easy browsing during data analysis.
        % * tag: The string or character vector that should be appended onto the timestamp when naming the expfolder.
        % * expfolder: returned copy of the updated expfolder property of the app.
        % * datafile: full filepath of the .mat file into which the experimental data will be saved.
        function [expfolder, datafile] = makeExperimentFolder(app, tag)
            expfolder = fullfile(app.datafolder, ...
                strcat(datestr(now, 'HHMMSS'), tag));
            datafile = fullfile(expfolder, 'output_data.mat');
            app.expfolder = expfolder;
            if ~exist(app.expfolder, 'dir')
                mkdir(app.expfolder);
            end
            app.datafile = datafile;
        end
        
        % This method sets the source of the app's explistener to the master_device input. 
        % This will normally be a Device, but will sometimes be the app itself. 
        % When the specified master_device fires a exp_finished event notification, 
        % the app will execute the expFinishedCallback method. 
        % If multiple devices are used in the experiment, 
        % assign the device that will be the last to fire an exp_finished event notification.
        % * master_device: The object to be assigned as the master_device and source for the app's explistener.
        function assignMasterDevice(app, master_device)
            app.explistener.Source = {master_device};
        end
        
        % This method specifies which devices should have their property values stored in the datafile for the experiment.
        % * devices: An array of device handles (likely generated by a previous GetDevice call) that should have their property values saved at the end of the experiment. Specify the devices array with brackets (e.g. [dev1,dev2,dev3]).
        function assignDevicesForMonitoring(app, devices)
            app.monitored_devices_index = zeros(1, numel(app.Devices));
            for i = 1:numel(devices)
                if ~isempty(devices(i))
                    app.monitored_devices_index = (app.monitored_devices_index | arrayfun(@(x)eq(devices(i), x), app.Devices));
                end
            end
        end
        
        function message = deleteJs(app, save)
            message = [];
            % Shut down all lasers, LEDs, shutters etc.
            for i = 1:length(app.Devices)
                if isa(app.Devices(i),"NI_DAQ_Modulator")
                    app.Devices(i).level = 0;
                elseif isa(app.Devices(i),"NI_DAQ_Shutter")
                    app.Devices(i).State = 0;
                end
            end

            cam = app.getDevice('Camera');
            for i = 1:length(cam)
                cam(i).Stop();
            end

            % Save data to server if requested
            if save
                app.copyToServer();
            end 

            % Delete app object
            app.wasAppDeletedFromJS = true;
            app.delete();
        end

        % resets the app if there is a problem with the JS frontend
        function reset(app)
            app.jsServer.flush();
        end

        % function reset_DAQ(app)
        %     if ~isempty(timerfindall)
        %         stop(timerfindall());
        %         delete(timerfindall());
        %     end
        %     dq_session = app.getDevice('DAQ');
        %     dq_session.rate = [];
        %     dq_session.trigger = [];
        %     dq_session.clock = [];
        %     dq_session.numsamples = [];
        %     dq_session.trigger_output_task = 
        %     if ~isempty(dq_session.buffered_tasks)
        %        dq_session.buffered_tasks = [];
        %     end
        % 
        %     dq_session.waveforms_built = 0;
        % end
        
        % Called automatically if the app object is cleared, and since we have it included in the CloseWindowCallback, it is also called when the window is closed. This method spawns a progress bar dialog that prompts the user to wait for their data to be copied over to the server, resets the DAQs, and then stops all of the timers.
        function delete(app)
            
            if ~app.wasAppDeletedFromJS && app.isDataAcquired
                app.promptUserToSaveDataToServer();
            end
            if ~isempty(timerfindall)
                stop(timerfindall());
                delete(timerfindall());
            end
            delete(app.jsServer);
        end
        
        % Callback when an experiment finishes. If screen was blanked, it turns it back on. Collects and saves data from tracked devices.
        function expFinishedCallback(app, src, evt)
            disp(app.explistener.Source{1}.name + " has completed acquisition.");
            if app.screen_blanked
                app.screen_blanked = false;
                % Briefly toggle to trigger listener if not aborted.
                pause(0.05);
                app.screen_blanked = true;
            end
            if app.VR_On
                writeline(app.VRclient, "stop")
                % the following two lines are needed to clear the client
                delete(app.VRclient)
                clear app.VRclient
            end
            tracked_devices = app.Devices(app.monitored_devices_index); %Builds a heterogeneous array of device handles, filtering only for those we want to monitor.
            for i = 1:numel(tracked_devices)
                tracked_devices(i).Wait_Until_Done();
            end
            disp("Done with experiment."); % Display finish message when all tracked devices are done.
            Device_Data{1} = app.buildAppArchive();
            for i = 1:numel(tracked_devices)
                Device_Data{i+1} = tracked_devices(i).Build_Archive;
            end
            if ~exist(app.datafile, 'file')
                save(app.datafile, 'Device_Data', '-v7.3') %saves the non-transient properties of the device object
            else
                save(app.datafile, 'Device_Data', '-append')
            end
            app.exp_complete = true;
            app.isDataAcquired = true;
        end

        function blank_all_screens(app)
            screens = get(0, 'MonitorPositions'); % Get monitor positions
            numScreens = size(screens, 1);        % Number of monitors
            app.blank_fig_handles = gobjects(numScreens, 1);       % Store figure handles

            % Create a listener for app.screen_blanked
            app.blank_listener = addlistener(app, 'screen_blanked', 'PostSet', @(src, evt) app.check_screen_status());

            % Create a fullscreen figure for each monitor
            for i = 1:numScreens
                app.blank_fig_handles(i) = figure('Name', 'Black Screen', ...
                                 'NumberTitle', 'off', ...
                                 'Color', 'black', ...
                                 'MenuBar', 'none', ...
                                 'ToolBar', 'none', ...
                                 'KeyPressFcn', @(src, event) close_all_figures(app), ...
                                 'Resize', 'off');
                
                % Vertically scale figure to cover up window border and
                % expose task bar at the bottom
                % screens(i,2) = screens(i,2) + 40;  
                % screens(i,4) = screens(i,4) + 80;  

                % Set the figure position and size to match the monitor
                set(app.blank_fig_handles(i), 'Position', screens(i, :), ...
                             'WindowState', 'normal', ...
                             'Units', 'pixels');

                drawnow; % Ensure the figure is fully created
                warning("off","all");
                try
                    javaFrame = get(handle(app.blank_fig_handles(i)), 'JavaFrame');
                    javaFrame_fHGClient = javaFrame.fHG2Client.getWindow();
                    javaFrame_fHGClient.setAlwaysOnTop(true);
                end
                warning("on","all");
            end
        end

        function check_screen_status(app)
            % Close figures if screen_blanked is set to false
            if ~app.screen_blanked
                warning('off','all');
                app.close_all_figures();
                warning('on','all');
            end
        end
    
        function close_all_figures(app)
            % Close all valid figures and clear the handles
            if ~isempty(app.blank_fig_handles)
                for i = 1:numel(app.blank_fig_handles)
                    if isvalid(app.blank_fig_handles(i))
                        close(app.blank_fig_handles(i));
                    end
                end
            end
            app.blank_fig_handles = gobjects(0); 

            % Delete the listener if it exists
            if isvalid(app.blank_listener)
                delete(app.blank_listener);
            end
           % app.blank_listener = []; % Clear the listener property
        end

        function update_blanking(app, blank)
            app.screen_blanked = blank;
        end
    end

    methods (Access = private)
        
        % This method searches the Rig_Initializer_Files folder for a .json file whos name matches the app's Rig property.
        % It loads the Rig_Init object stored in that file and then stores it in the app's Rig_Init property.
        % It then searches the Users folder for a .json file whos name matches the app's username property, loads the User_Key object from that file,
        % and assignes the User_Key object to the User property of the app.
        % Next, the method opens the rig's logfile and notes the time and the user who is running the app.
        % It then stores the paths to directories into which experimental data will be written.
        function loadInitData(app, username)
            % load Rig_Init, Key and make/set files to store data
            
            Rig_Init_filename = strcat(app.rigName, '.json');
            app.Rig_Init = load_init(Rig_Init_filename);
            
            % load user key
            if username == "Unknown username"
                % default user
                app.User = User_Key();
                app.User.name = username;
            else
                User_Key_filepath = fullfile(app.basepath, 'src', 'Users', strcat(username, '.json'));
                app.User = load_init(User_Key_filepath);
            end
            
            if (isempty(app.Rig_Init.dataDirectory) || ~isfolder(app.Rig_Init.dataDirectory))
                switch questdlg(sprintf("Directory %s does not exist. Would you like to create it?", app.Rig_Init.dataDirectory), 'Directory not found', 'Create Directory', 'Cancel', 'Create Directory');
                    case 'Cancel'
                        error("Directory %s does not exist. Please modify init file with valid directory", app.Rig_Init.dataDirectory);
                    case 'Create Directory'
                        mkdir(app.Rig_Init.dataDirectory);
                end
            end
            app.logfile = fullfile(app.Rig_Init.dataDirectory, 'logfile.txt');
            if exist(app.logfile, 'file') == 2
                fid = fopen(app.logfile, 'at');
            else
                fid = fopen(app.logfile, 'wt');
            end
            fprintf(fid, strcat('App Launched by', " ", char(app.User.name), '...', datestr(now, 'YYYYmmdd - HH:MM:SS'), '\n'));
            fclose(fid);
            
            if ~isempty(app.Experiment)
                app.datafolder = fullfile(app.Rig_Init.dataDirectory, app.User.name, app.Experiment, datestr(now, 'YYYYmmdd'));
                app.server_target = fullfile(app.User.server_directory, app.Experiment, datestr(now, 'YYYYmmdd'));
            else
                app.datafolder = fullfile(app.Rig_Init.dataDirectory, app.User.name, datestr(now, 'YYYYmmdd'));
                app.server_target = fullfile(app.User.server_directory, datestr(now, 'YYYYmmdd'));
            end
            if ~exist(app.datafolder, 'dir')
                mkdir(app.datafolder);
            end

            % save tabs
            app.tabs = app.Rig_Init.tabs;
        end
        
        % This method constructs the device objects specified in the Rig_Init object and stores them in the app's Devices property.
        function attachDevices(app)
            app.Devices = Device.empty();
            for i = 1:numel(app.Rig_Init.devices)
                try
                    app.Devices(i) = app.Rig_Init.devices(i).Construct_Device();
                catch me
                    problematic_device = app.Rig_Init.devices(i).name;
                    warning(['Problem Loading ', char(problematic_device)])
                    
                    % reports full error messages (useful for debugging)
                    disp(getReport(me, 'extended', 'hyperlinks', 'on'));
                    
                    % return an empty device
                    device = Placeholder();
                    device.name = problematic_device;
                    app.Devices(i) = device;
                end
            end
        end
        
        function Archive = buildAppArchive(app)
            mc = metaclass(app);
            proplist = mc.PropertyList;
            props2save = findobj(proplist, 'Transient', false);
            props2save = props2save(~(contains({props2save.Name}, 'Components') | contains({props2save.Name}, 'ServerEnd')));
            names = {props2save.Name};
            Archive = cell2struct(get(app, names), names, 2);
            tracked_devices = app.Devices(app.monitored_devices_index);
            if isempty(tracked_devices)
                Archive.Archive_Index.Device_Name = [];
                Archive.Archive_Index.deviceType = [];
            else
                for i = 1:numel(tracked_devices)
                    Archive.Archive_Index(i).Device_Name = tracked_devices(i).name;
                    Archive.Archive_Index(i).deviceType = class(tracked_devices(i));
                end
            end
        end
        
        % Copies the data from the day into the user's directory on the lab server.
        % Throws a warning if something goes wrong so the user knows to copy the data over manually.
        function copyToServer(app)
            fprintf('Copying Data Files to Server...\n');
            if ~exist(app.server_target, 'dir')
                try
                    mkdir(app.server_target);
                catch
                    warning('Problem Copying to Server. Please copy the data over manually.');
                    
                end
            end
            try
                copyfile(app.datafolder, app.server_target);
                fprintf('Done \n');
            catch
                warning('Problem Copying to Server. Please copy the data over manually.')
            end
        end
        
        function promptUserToSaveDataToServer(app)
            % prompt user if they want to copy data to server
            % show them their app.server_target
            answer = questdlg(sprintf('Would you like to copy the data to the server? \n\nIt will be saved in %s', app.server_target), ...
                'Copy to Server', ...
                'Yes', 'No', 'No');
            
            if strcmp(answer, 'Yes')
                app.copyToServer();
            end
        end
        
    end

end
