classdef (Abstract) alpapi < handle & alpconstants
    % ALPAPI  abstract class that provides access to the ALP APIs
    %
    %   class  alpapi  is inhereted from classes handle and alpconstats.
    %   It provides access to the "ALP" API developed by Vialux GmbH, Germany,
    %   for the control of DMDs (digital micromirror devices)
    %
    % Methods:
    %   isloaded = dllisloaded(obj)  check whether DLL is loaded
    %   [xval] = log(obj, message, varargin)  wrapper method to logger object
    %
    % Properties:
    %   class  displogger  has no public properties.
    %
    % See also:
    %   alpV1x32, alpV42x32, alpV42x64
    %
    % File information:
    %   version 1.0 (feb 2014)
    %   (c) Martin Vogel
    %   email: matlab@martin-vogel.info
    %
    % Revision history:
    %   1.0 (feb 2014) initial release version
    %

    % +++++++++++++++++++++++++++++++++++++++++++++++++++++++
    % constants from header file
    properties (SetAccess = protected)
        DEFAULT = int32(0);
        CURRENT_SOFTWARE_VERSION = '1.2';

        % DLL return codes
        % OK = int32(0);                % successfull execution
        NOT_ONLINE = int32(1001); % The specified ALP has not been found or is not ready.
        NOT_IDLE = int32(1002); % The ALP is not in idle state.
        NOT_AVAILABLE = int32(1003); % The specified ALP identifier is not valid.
        NOT_READY = int32(1004); % The specified ALP is already allocated.
        PARM_INVALID = int32(1005); % One of the parameters is invalid.
        ADDR_INVALID = int32(1006); % Error accessing user data.
        MEMORY_FULL = int32(1007); % The requested memory is not available.
        SEQ_IN_USE = int32(1008); % The sequence specified is currently in use.
        HALTED = int32(1009); % The ALP has been stopped while image data transfer was active.
        ERROR_INIT = int32(1010); % Initialization error.
        ERROR_COMM = int32(1011); % Communication error.
        DEVICE_REMOVED = int32(1012); % The specified ALP has been removed.
        NOT_CONFIGURED = int32(1013); % The onboard FPGA is unconfigured.
        LOADER_VERSION = int32(1014); % The function is not supported by this version of the driver file VlxUsbLd.sys.

        % for ALP_DEV_STATE in AlpDevInquire
        DEV_BUSY = int32(1100); % the ALP is displaying a sequence or image data download is active
        DEV_READY = int32(1101); % the ALP is ready for further requests
        DEV_IDLE = int32(1102); % the ALP is in wait state

        % for ALP_PROJ_STATE in AlpProjInquire
        PROJ_ACTIVE = int32(1200); % ALP projection active
        PROJ_IDLE = int32(1201); % no projection active

        % parameter

        % AlpDevInquire
        %
        DEVICE_NUMBER = int32(2000); % Serial number of the ALP device
        VERSION = int32(2001); % Version number of the ALP device
        DEV_STATE = int32(2002); % current ALP status, see above
        AVAIL_MEMORY = int32(2003); % ALP on-board sequence memory available for further sequence
        % allocation (AlpSeqAlloc); number of binary pictures

        % AlpDevControl - ControlTypes & ControlValues
        TRIGGER_POLARITY = int32(2004); % Select trigger output signal polarity
        VD_EDGE = int32(2005); % Select active VD input trigger edge (slave mode)
        LEVEL_HIGH = int32(2006); % Active high trigger output
        LEVEL_LOW = int32(2007); % Active low trigger output
        EDGE_FALLING = int32(2008); % High to low signal transition
        EDGE_RISING = int32(2009); % Low to high signal transition

        VD_TIME_OUT = int32(2014); % VD trigger time-out (slave mode)
        TIME_OUT_ENABLE = int32(0); % Time-out enabled (default)
        TIME_OUT_DISABLE = int32(1); % Time-out disabled

        USB_CONNECTION = int32(2016); % Re-connect after a USB interruption

        DEV_DMDTYPE = int32(2021); % Select DMD type; only allowed for a new allocated ALP-3 high-speed device

        % AlpSeqControl - ControlTypes
        SEQ_REPEAT = int32(2100); % Non-continuous display of a sequence (AlpProjStart) allows
        % for configuring the number of sequence iterations.
        SEQ_REPETE = int32(2100); % According to the typo made in primary documentation (ALP API description)
        FIRSTFRAME = int32(2101); % First image of this sequence to be displayed.
        LASTFRAME = int32(2102); % Last image of this sequence to be displayed.

        BITNUM = int32(2103); % A sequence can be displayed with reduced bit depth for faster speed.
        BIN_MODE = int32(2104); % Binary mode: select from ALP_BIN_NORMAL and ALP_BIN_UNINTERRUPTED (AlpSeqControl)

        BIN_NORMAL = int32(2105); % Normal operation with progammable dark phase
        BIN_UNINTERRUPTED = int32(2106); % Operation without dark phase

        DATA_FORMAT = int32(2110); % Data format and alignment
        DATA_MSB_ALIGN = int32(0); % Data is MSB aligned (default)
        DATA_LSB_ALIGN = int32(1); % Data is LSB aligned
        DATA_BINARY_TOPDOWN = int32(2); % Data is packed binary, top row first; bit7 of a byte = leftmost of 8 pixels
        DATA_BINARY_BOTTOMUP = int32(3); % Data is packed binary, bottom row first
        % XGA:   one pixel row occupies 128 byte of binary data.
        %        Byte0.Bit7 = top left pixel (TOPDOWN format)
        % SXGA+: one pixel row occupies 176 byte of binary data. First byte ignored.
        %        Byte1.Bit7 = top left pixel (TOPDOWN format)

        % AlpSeqInquire
        BITPLANES = int32(2200); % Bit depth of the pictures in the sequence
        PICNUM = int32(2201); % Number of pictures in the sequence
        PICTURE_TIME = int32(2203); % Time between the start of consecutive pictures in the sequence in microseconds,
        % the corresponding in frames per second is
        % picture rate [fps] = 1 000 000 / ALP_PICTURE_TIME [µs]
        ILLUMINATE_TIME = int32(2204); % Duration of the display of one picture in microseconds
        TRIGGER_DELAY = int32(2205); % Delay of the start of picture display with respect
        % to the trigger output (master mode) in microseconds
        TRIGGER_PULSEWIDTH = int32(2206); % Duration of the active trigger output pulse in microseconds
        VD_DELAY = int32(2207); % Delay of the start of picture display with respect to the
        % active VD trigger input edge in microseconds
        MAX_TRIGGER_DELAY = int32(2209); % Maximal duration of trigger output to projection delay in microseconds
        MAX_VD_DELAY = int32(2210); % Maximal duration of trigger input to projection delay in microseconds

        MIN_PICTURE_TIME = int32(2211); % Minimum time between the start of consecutive pictures in microseconds
        MIN_ILLUMINATE_TIME = int32(2212); % Minimum duration of the display of one picture in microseconds
        % depends on ALP_BITNUM and ALP_BIN_MODE
        MAX_PICTURE_TIME = int32(2213); % Maximum value of ALP_PICTURE_TIME

        % ALP_PICTURE_TIME = ALP_ON_TIME + ALP_OFF_TIME
        % ALP_ON_TIME may be smaller than ALP_ILLUMINATE_TIME
        ON_TIME = int32(2214); % Total active projection time
        OFF_TIME = int32(2215); % Total inactive projection time

        % AlpProjControl - ControlTypes & ControlValues
        PROJ_MODE = int32(2300); % Select from ALP_MASTER and ALP_SLAVE_VD mode
        MASTER = int32(2301); % The ALP operation is controlled by internal
        % timing, a trigger signal is sent out for any
        % picture displayed
        SLAVE_VD = int32(2302); % The ALP operation is controlled by external
        % trigger, the next picture in a sequence is
        % displayed after the detection of an external
        % input trigger (VD or composite-video) signal.
        PROJ_SYNC = int32(2303); % Select from ALP_SYNCHRONOUS and ALP_ASYNCHRONOUS mode
        SYNCHRONOUS = int32(2304); % The calling program gets control back after completion
        % of sequence display.
        ASYNCHRONOUS = int32(2305); % The calling program gets control back immediatelly.

        PROJ_INVERSION = int32(2306); %  Reverse dark into bright
        PROJ_UPSIDE_DOWN = int32(2307); %  Turn the pictures upside down

        % AlpProjInquire
        %  ALP_PROJ_MODE
        %  ALP_PROJ_SYNC
        PROJ_STATE = int32(2400);
    end

    % +++++++++++++++++++++++++++++++++++++++++++++++++++++++
    % properties
    properties
        pseudoDLL = false; % turn on/off pseudo DLL calls
    end

    % +++++++++++++++++++++++++++++++++++++++++++++++++++++++
    % protected properties
    properties (SetAccess = protected)
        classname = [];
        dllfile = [];
        protofile = [];
        protofunc = [];
        arch = [];
        libalias = []; % alias name for DLL
    end

    % +++++++++++++++++++++++++++++++++++++++++++++++++++++++
    properties (SetAccess = protected, GetAccess = protected)
        p_logger = []; % logger object
    end

    % +++++++++++++++++++++++++++++++++++++++++++++++++++++++
    % methods
    methods
        function isloaded = dllisloaded(obj)
            % dllisloaded  check whether DLL is loaded
            if obj.pseudoDLL
                isloaded = true;
            else
                isloaded = libisloaded(obj.libalias);
            end
        end

        function [xval] = log(obj, message, varargin)
            % log  wrapper method to logger object
            xval = obj.p_logger.(message)(varargin{:});
        end

    end

end
