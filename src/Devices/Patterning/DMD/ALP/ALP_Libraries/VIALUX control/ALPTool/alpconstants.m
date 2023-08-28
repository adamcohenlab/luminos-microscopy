classdef alpconstants < handle
    % ALPCONSTANTS  class that defines additional constants not found in the C API
    %               by Vialux GmbH, Gemany
    %
    % File information:
    %   version 1.0 (feb 2014)
    %   (c) Martin Vogel
    %   email: matlab@martin-vogel.info
    %
    % Revision history:
    %   1.0 (feb 2014) initial release version
    %

    % constants for common return values
    properties (SetAccess = protected)
        % NOTE: return value constants <0 not defined by alp.dll -> we can use them for
        % our purposes
        OK = 0;
        LIBRARY_NOT_LOADED = -1;
        MISSING_PARAMETERS = -2;
        INVALID_ID = -3;
    end

end
