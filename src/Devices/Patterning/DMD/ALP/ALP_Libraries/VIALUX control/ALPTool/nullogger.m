classdef nullogger < logger
    % NULLOGGER  LOGGER class that prints to nowhere
    %
    %   class  nullogger  is inhereted from class logger and
    %   implements a logger that prints all information to
    %   nowhere (similar to "> /dev/null" on *nix systems).
    %   This class is useful to suppress all logging activity.
    %
    % Methods:
    %   oNL = nullogger()   instantiates a nullogger object
    %   str = oNL.log(str)  prints log string to nowhere
    %   delete(oNL)         deletes nullogger object
    %
    % Properties:
    %   class  nullogger  has no public properties.
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

        function obj = nullogger()
            % nullogger  instantiate a nullogger object
        end

        function str = log(obj, str) %#ok<INUSL>
            % log  print log information to nowhere
        end

        function delete(obj) %#ok<INUSD>
            % delete  delete nullogger object
        end

    end

end
