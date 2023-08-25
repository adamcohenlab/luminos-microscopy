classdef displogger < logger
    % DISPLOGGER  LOGGER class that prints to MATLAB console
    %
    %   class  displogger  is inhereted from class logger and
    %   implements a logger that prints all information to
    %   the MATLAB console using disp
    %
    % Methods:
    %   oDL = displogger()  instantiates a displogger object
    %   str = oDL.log(str)  prints log string to MATLAB console
    %   delete(oDL)         deletes displogger object
    %
    % Properties:
    %   class  displogger  has no public properties.
    %
    % File information:
    %   version 1.0 (feb 2014)
    %   (c) Martin Vogel
    %   email: matlab@martin-vogel.info
    %
    % Revision history:
    %   1.0 (feb 2014) initial release version
    %
    % See also:
    %   filelogger, textfilelogger, logger

    % +++++++++++++++++++++++++++++++++++++++++++++++++++++++
    properties (SetAccess = public, GetAccess = public)
    end

    % +++++++++++++++++++++++++++++++++++++++++++++++++++++++
    properties (SetAccess = protected, GetAccess = public)
    end

    % +++++++++++++++++++++++++++++++++++++++++++++++++++++++
    properties (SetAccess = protected, GetAccess = protected)
    end

    % +++++++++++++++++++++++++++++++++++++++++++++++++++++++
    methods

        function obj = displogger()
            % instantiate displogger object
            obj.level = 0;
        end

        function str = log(obj, str)
            % log  print log string to MATLAB console
            fprintf([repmat('\t', [1, obj.level]), '%s\n'], str);
        end

        function delete(obj) %#ok<INUSD>
            % delete  delete displogger object
        end

    end

end
