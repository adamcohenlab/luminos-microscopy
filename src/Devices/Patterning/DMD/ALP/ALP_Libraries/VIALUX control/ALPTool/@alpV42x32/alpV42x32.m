classdef alpV42x32 < alpapi
    %alpV42x32 provides access to the ALP Highspeed API, v4.2, 32bit
    %
    %   Class alpV42x32 is derived from the abstract class alpapi and
    %   provides access to functions and constants defined in alp.h (version 7) and
    %   alpV42.dll, 32 bit.
    %
    %  File information:
    %     version 1.0 (feb 2014)
    %     email: matlab@martin-vogel.info
    %
    %  Revision history:
    %     1.0 (feb 2014) initial release version

    % additional constants from header file (version 7)
    properties (SetAccess = protected)
        ERROR_DONGLE = int32(1015); % Please connect the USB Dongle */
        % Temperatures. Data format: signed long with 1 LSB=1/256 °C
        DDC_FPGA_TEMPERATURE = int32(2050); % V4100 Rev B: LM95231.
        % External channel: DDC FPGAs Temperature Diode
        APPS_FPGA_TEMPERATURE = int32(2051); % V4100 Rev B: LM95231.
        % External channel: Application FPGAs Temperature Diode
        PCB_TEMPERATURE = int32(2052); % V4100 Rev B: LM95231.
        % Internal channel. "Board temperature"

        DMDTYPE_XGA = int32(1); % 1024*768 mirror pixels (0.7" Type A, D3000)
        DMDTYPE_SXGA_PLUS = int32(2); % 1400*1050 mirror pixels (0.95" Type A, D3000)
        DMDTYPE_1080P_095A = int32(3); % 1920*1080 mirror pixels (0.95" Type A, D4x00)
        DMDTYPE_XGA_07A = int32(4); % 1024*768 mirror pixels (0.7" Type A, D4x00)
        DMDTYPE_XGA_055A = int32(5); % 1024*768 mirror pixels (0.55" Type A, D4x00)
        DMDTYPE_XGA_055X = int32(6); % 1024*768 mirror pixels (0.55" Type X, D4x00)
        DMDTYPE_DISCONNECT = int32(255); % behaves like 1080p (D4100)

        FIRSTLINE = int32(2111); % Start line position at the first image
        LASTLINE = int32(2112); % Stop line position at the last image
        LINE_INC = int32(2113); % Line shift value for the next frame

        % LED API

        % Valid LedTypes for AlpLedAlloc:
        % LED Driver: HLD, LED: red/green/blue/near-UV PT120, see API
        % documentation for compatible types
        HLD_PT120_RED = int32(257);
        HLD_PT120_GREEN = int32(258);
        HLD_PT120_BLUE = int32(259);
        HLD_PT120_390 = int32(260);
        HLD_PT120_405 = int32(261);

        % Valid ControlTypes for AlpLedControl
        LED_SET_CURRENT = int32(1001); % set up nominal LED current. Value = milli amperes
        LED_BRIGHTNESS = int32(1002); % set up brightness on base of ALP_LED_CURRENT.

        % Valid InquireTypes for AlpLedInquire
        % ALP_LED_SET_CURRENT: actually set-up value; it may slightly differ from the Value used in AlpLedControl
        % ALP_LED_BRIGHTNESS: value as in AlpLedControl
        LED_TYPE = int32(1101); % LedType of this LedId
        LED_MEASURED_CURRENT = int32(1102); % measured LED current in milli amperes
        LED_TEMPERATURE_REF = int32(1103); % measured LED temperature at the NTC temperature sensor
        LED_TEMPERATURE_JUNCTION = int32(1104); % calculated LED junction temperature on base of
        % ALP_LED_TEMPERATURE_REF and a default (?) thermal model

        % Valid InquireTypes for AlpLedInquireEx:
        LED_ALLOC_PARAMS = int32(2101); % retrieve actual alloc parameters; especially useful if omitted in the AlpLedAlloc call
    end

    methods
        % constructor
        function obj = alpV42x32(tag, pseudoDLL, logger)

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
                    error('alpV42x32:dllnotinstalled', 'ALP v4 32 bit: Specified DLL is not installed');
                end
                if ~strcmp(alplibs.arch, computer('arch'))
                    % architecture mismatch
                    error('alpV42x32:architecturemismatch', 'ALP v4 32 bit: Architecture mismatch');
                end
                if isempty(alplibs.classname)
                    % DLL not registered in alplibs.m
                    error('alpV42x32:notregistered', 'ALP v4 32 bit: Not registered in alplibs.m');
                end
                if isempty(alplibs.dllfile) || ~exist(alplibs.dllfile, 'file')
                    % DLL is not available on this system
                    error('alpV42x32:nodll', 'ALP v4 32 bit: DLL is not available');
                end
                if isempty(alplibs.protofile) || ~exist(alplibs.protofile, 'file')
                    % prototype file is not available on this system
                    error('alpV42x32:noproto', 'ALP v4 32 bit: Prototype file is not available');
                end

                obj.libalias = 'alpV42x32';
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
