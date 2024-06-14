classdef RAS_Master < handle
    properties (Transient)
        server_socket tcpserver.internal.TCPServer
        app Rig_Control_App
        cfcl_ref_file
    end

    methods
        function msgRcvCallback(obj, ~, ~)
            msg = char(readline(obj.server_socket));
            feval(msg, obj);
        end
    end

    methods
        function obj = RAS_Master(app)
            obj.server_socket = tcpserver("0.0.0.0", 3000);
            configureCallback(obj.server_socket, "terminator", @(src, evt)msgRcvCallback(obj, src, evt));
            obj.app = app;
        end

        function Get_Snap(obj)
            cam = obj.app.getDevice('Camera');
            snapdata = cam.Snap();
            obj.server_socket.write(uint16(snapdata(:)), "uint16");
        end

        function Copy_Snaps(obj)
            copyfile(fullfile(obj.app.datafolder, 'Snaps/*'), 'X:/Lab/Labmembers/Hunter Davis/Network_Dropbox/')
        end

        function Run_GS(obj)
            data = double(readline(obj.server_socket));
            mat = reshape(data, [512, 512]);
            [sol, est] = RAS_SLM_routine(Target, 1000, 1, 512);
            write(obj.server_socket, sol);
        end

    end
end
