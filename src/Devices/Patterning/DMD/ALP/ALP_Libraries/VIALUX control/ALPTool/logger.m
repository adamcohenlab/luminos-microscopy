classdef (Abstract) logger < handle
    % LOGGER  Abstract base class for all LOGGERs
    %
    %   class  logger  is the abstract base class for all
    %   logger classes in this package
    %
    % Methods:
    %   str = obj.log(str)  logs data (abstract)
    %   level = obj.push()  pushes logging level by one
    %   level = obj.pop()   pop logging level by one
    %
    % Properties:
    %   obj.level  the current logging level (read-only)
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
    %   filelogger, textfilelogger, displogger

    % +++++++++++++++++++++++++++++++++++++++++++++++++++++++
    properties (SetAccess = public, GetAccess = public)
    end

    % +++++++++++++++++++++++++++++++++++++++++++++++++++++++
    properties (SetAccess = protected, GetAccess = public)
        level = 0;
    end

    % +++++++++++++++++++++++++++++++++++++++++++++++++++++++
    properties (SetAccess = protected, GetAccess = protected)
    end

    % +++++++++++++++++++++++++++++++++++++++++++++++++++++++
    methods (Abstract = true)
        str = log(obj, str)
    end

    methods
        function level = push(obj)
            % push  push logging level by one
            obj.level = obj.level + 1;
            level = obj.level;
        end

        function level = pop(obj)
            % pop  pop logging level by one
            if obj.level > 0
                obj.level = obj.level - 1;
            end
            level = obj.level;
        end
    end

end
