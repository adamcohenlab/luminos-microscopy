classdef alpV1x32 < alpapi
    %alpv1x32 provides access to the ALP Highspeed API, v1.x, 32bit
    %
    %   Class alpV1x32 is derived from the abstract class alpapi and
    %   provides access to functions and constants defined in alp.h (version 4) and
    %   alpV.dll, 32 bit.
    %
    %  File information:
    %     version 1.0 (feb 2014)
    %     email: matlab@martin-vogel.info
    %
    %  Revision history:
    %     1.0 (feb 2014) initial release version

    % additional constants from header file
    properties (SetAccess = protected)
        DMDTYPE_XGA = int32(1); % 1024*768 mirror pixels
        DMDTYPE_SXGA_PLUS = int32(2); % 1400*1050 mirror pixels
    end

    methods

        % -----------
        % constructor
        % -----------
        function obj = alpV1x32(tag, pseudoDLL, logger)

            if nargin >= 2 && pseudoDLL

                obj.libalias = [];
                obj.pseudoDLL = true;

                obj.classname = [];
                obj.dllfile = [];
                obj.protofile = [];
                obj.protofunc = [];
                obj.arch = [];

            else

                alplibs = alplib('get', tag);
                if isempty(alplibs)
                    % architecture mismatch
                    error('alpV1x32:dllnotinstalled', 'ALP v1.x 32 bit: Specified DLL is not installed');
                end
                if ~strcmp(alplibs.arch, computer('arch'))
                    % architecture mismatch
                    error('alpV1x32:architecturemismatch', 'ALP v1.x 32 bit: Architecture mismatch');
                end
                if isempty(alplibs.classname)
                    % DLL not registered in alplibs.m
                    error('alpV1x32:notregistered', 'ALP v1.x 32 bit: Not registered in alplibs.m');
                end
                if isempty(alplibs.dllfile) || ~exist(alplibs.dllfile, 'file')
                    % DLL is not available on this system
                    error('alpV1x32:nodll', 'ALP v1.x 32 bit: DLL is not available');
                end
                if isempty(alplibs.protofile) || ~exist(alplibs.protofile, 'file')
                    % prototype file is not available on this system
                    error('alpV1x32:noproto', 'ALP v1.x 32 bit: Prototype file is not available');
                end

                obj.libalias = 'alpV1x32';
                if ~libisloaded(obj.libalias)
                    % prevent multiple DLL loadings
                    loadlibrary(alplibs.dllfile, alplibs.protofunc, 'alias', obj.libalias);
                end

                obj.pseudoDLL = false;

                obj.classname = alplibs.classname;
                obj.dllfile = alplibs.dllfile;
                obj.protofile = alplibs.protofile;
                obj.protofunc = alplibs.protofunc;
                obj.arch = alplibs.arch;

            end

            % set logger
            if nargin >= 3 && isa(logger, 'logger')
                obj.p_logger = logger;
            else
                obj.p_logger = nullogger();
            end

        end

        % -------------
        % deconstructor
        % -------------
        function delete(obj)
            if ~obj.pseudoDLL && ~isempty(obj.libalias)
                unloadlibrary(obj.libalias);
            end
            obj.libalias = [];
        end

    end

end
