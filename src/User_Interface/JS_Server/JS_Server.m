%T his class implements the matlab side of the JS-Matlab communications. It
% talks to Data_Relay.js, which passes messages to and from MatlabComms.jsx
% It requires InstrumentControl toolbox for tcpip communication

classdef JS_Server < handle
    properties (Transient)
        server_socket tcpserver.internal.TCPServer
        cfcl_ref_file
        app Rig_Control_App
    end
    
    
    
    methods
        function obj = JS_Server(app)
            obj.app = app;
            
            % stop any running node processes
            obj.stopJsApp();
            
            obj.server_socket = tcpserver(app.jsPort, "ByteOrder", "little-endian");
            configureCallback(obj.server_socket, "terminator", @(src, evt)msgRcvCallback(obj, src, evt));
            obj.startJsApp();
        end

        % If Matlab is receiving a lot of data, it can
        % get backed up and the luminos screen can go blank.
        % 
        % This function will flush the socket and clear the buffer, which should restore the screen. 
        function flush(obj)
            obj.server_socket.flush();
        end
        
        function delete(obj)
            obj.server_socket.delete();
            obj.stopJsApp();
        end
    end
    
    methods (Access=private)
        function startJsApp(obj)
            % start the react app
            cmd = "npm start";
            
            % get the path to the frontend folder
            frontend_path = fullfile(obj.app.basepath, "src", "User_Interface", "frontend");
            
            % run npm start and display the output with -echo
            cmd = "cd " + frontend_path + " && " + cmd + "&";
            [status, cmdout] = system(cmd, "-echo");
            
            % launch the app in the browser
            web("http://localhost:3000", "-browser");
        end
        
        function msgRcvCallback(obj, ~, ~)
            % the msg should be used to excecute one of four functions.
            % 1. It can call an application script, which uses the app handle passed on construction.
            % 2. It can set a device property using the set method, which is defined for all virtual
            %    devices as they inherit from the setget class.
            % 3. It can get a device property using the get method.
            % 4. It can call a device method and get a return value passed back.
            
            msg = jsondecode(char(readline(obj.server_socket)));
            
            try
                % run app method
                if msg.type == "app_method"
                    obj.runAndWriteBack(msg.return_event, msg.method, obj.app, msg.args);
                else
                    % use devices
                    
                    % get devname if it exists
                    if isfield(msg, "devname")
                        devname = msg.devname;
                    else
                        devname = [];
                    end
                    
                    % get the device
                    device = obj.app.getDevice(msg.devtype, "name", devname, "displayWarning", false);
                    
                    if msg.type == "set_property"
                        set(device, msg.property, msg.value);
                        
                        % return 1 for success
                        ret = 1;
                        obj.write(msg.return_event, ret);
                        
                    elseif msg.type == "get_properties"
                        info.numDevices = length(device);
                        for i = 1:length(msg.properties)
                            if info.numDevices > 1
                                list = {};
                                for j = 1:info.numDevices
                                    list{j} = get(device(j), msg.properties{i});
                                end
                            else
                                list = get(device, msg.properties{i});
                            end
                            
                            info.(msg.properties{i}) = list;
                            
                        end
                        obj.write(msg.return_event, info);
                    elseif msg.type == "dev_method"
                        obj.runAndWriteBack(msg.return_event, msg.method, device, msg.args);
                    end
                end
            catch ME
                obj.write(msg.return_event, struct("error", ME.message));
                disp(getReport(ME));
                disp("Error msg:")
                disp(msg);
            end
        end
        
        function out = isLargeArray(obj, data)
            % max size for using jsonencode
            SMALL_DATA_SIZE = 1e4;
            out = isnumeric(data) && numel(data) > SMALL_DATA_SIZE;
            
        end
        
        function write(obj, event, data)
            % send metadata msg. If data is too big, send it as a float32
            % array after the metadata.
            
            % if data is empty, return (Note: this means you can't currently send empty arrays)
            if isempty(data) || (isstruct(data) && isempty(fieldnames(data)))
                return
            end
            
            msg.event = event;
            send_as_arr = false;
            if obj.isLargeArray(data)
                % send using float32 array since jsonencode is too slow
                msg.arrLength = numel(data);
                data = single(data);
                send_as_arr = true;
            else
                msg.data = data;
            end
            
            msg = jsonencode(msg);
            obj.server_socket.writeline(msg);
            
            if send_as_arr
                obj.server_socket.write(data, "single");
            end
            
        end
        
        function stopJsApp(obj)
            % kill all node processes and close the terminal
            % we need to close node forcefully because otherwise it asks for confirmation
            % a little sketchy, but it works
            [status, cmdout] = system("taskkill /im node.exe /f && taskkill /im cmd.exe"); %Ideally, we shouldn't close all cmd.exe instances...
        end
        
        % run the method and write the return value back to the client
        function runAndWriteBack(obj, return_event, methodName, msgObj, argsArray)
            
            args = toCell(argsArray);
            
            % get the number of output variables for the method
            numOutputs = obj.getNumOutputArgs(msgObj, methodName);
            
            if numOutputs == 0
                % run the method on the msgObj object (could be app or device)
                feval(methodName, msgObj, args{:});
                
                % return 1 for success
                ret = 1;
            elseif numOutputs == 1
                ret = feval(methodName, msgObj, args{:});
            else
                error("Methods with more than one output are not supported.")
            end
            
            % send the return value back to the client
            if ~isempty(ret)
                obj.write(return_event, ret);
            end
        end
        
        % get the number of outputs for the method
        function numOutputs = getNumOutputArgs(obj, msgObj, methodName)
            % get the metaclass of the object
            mc = metaclass(msgObj);
            
            % find the method in the method list
            for i = 1:length(mc.MethodList)
                if strcmp(mc.MethodList(i).Name, methodName)
                    numOutputs = length(mc.MethodList(i).OutputNames);
                    return
                end
            end
            
            % if the method is not found, check the scripts that aren't explicit methods of Rig_Control_App
            % but that are Experimental_Scripts
            if isa(msgObj, "Rig_Control_App")
                numOutputs = nargout(methodName);
                return
            end
            error("Method %s not found for %s", methodName, class(msgObj));
        end
    end
end