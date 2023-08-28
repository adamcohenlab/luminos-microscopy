function varargout = alplib(command, varargin)
% function varargout = alplib(command, varargin)
% APLIB  controls access to data base of registered ALP DLLs
%
%   command  is one of these keywords:
%   'exist', 'delete', 'get', 'set', 'empty', 'select'
%
%   varargin takes additional arguments for one of the commands above
%
%   varargout takes the output arguments for the given command
%
%   command 'exist': returns true of false depending on the existence of
%                    a API registration data base. No additional input
%                    arguments.
%
%   command 'delete': deletes an existing API registration data base. No
%                     additional input arguments. No output arguments.
%
%   command 'get': Searches for specific DB record (specified by tag name in
%                  first additional argument) or all records (if no additional
%                  input argument is given). Output is an structure array of
%                  records found (which may be an empty array if no record is found).
%
%   command 'set': Adds a new registration record to the data base. Additional parameters must
%                  be pairs of field names and content. All fields must be supplied:
%                  'tag': tag name (must be unique in the DB)
%                  'classname': name of the associated API class
%                  'pseudoDLL': true if DLL loading is only simulated
%                  'dllfile': full path and name to the DLL file,
%                             for use with loadlibrary (can be empty if pseudoDLL is true)
%                  'protofile': M-file that contains the DLL function prototypes
%                  'protofunc': function handle calling the protofile, for use with loadlibrary
%                  'arch': architecture, either 'win32' or 'win64'. Use to prevent loading of
%                          wrong architecture.
%
%   command 'empty': returns an empty structure array of registration records. No additional
%                    input arguments.
%
%   command 'select': Interactive API selection by user, prompting string can be supplied by
%                     additional argument. Will return selected record structure or empty if
%                     user aborted selection.
%
% File information:
%   version 1.0 (feb 2014)
%   (c) Martin Vogel
%   email: matlab@martin-vogel.info
%
% Revision history:
%   1.0 (feb 2014) initial release version
%

libfilename = [fileparts(mfilename('fullpath')), '\alplib.mat'];

switch command
    case 'exist'
        % check whether database exist
        varargout{1} = exist(libfilename, 'file');

    case 'delete'
        % delete database
        delete(libfilename);

    case 'get'
        % get all or specific record(s)
        filepathHD = fileparts(mfilename('fullpath'));
        if alplib('exist')
            salplibs = load(libfilename);
            if isfield(salplibs, 'alplibs')
                alplibs = salplibs.alplibs;
            else
                % house keeping: delete wrong db
                alplib('delete');
                alplibs = alplib('empty');
            end
        else
            alplibs = alplib('empty');
        end

        % filter for supplied tag
        if nargin > 1 && ischar(varargin{1})
            si = 1;
            while si <= length(alplibs)
                alplibs(si).dllfile = [filepathHD, '\', alplibs(si).dllfile]; %Hack from Hunter to make path relative for portability
                if ~strcmp(alplibs(si).tag, varargin{1})
                    alplibs(si) = [];
                else
                    si = si + 1;
                end
            end
        end
        varargout{1} = alplibs;

    case 'set'
        % add new record (must have unique tag!)

        % fill structure
        al = alplib('empty');
        if length(varargin) >= 2
            al(end+1).(varargin{1}) = varargin{2};
        end
        for vi = 3:2:length(varargin)
            al.(varargin{vi}) = varargin{vi+1};
        end

        % check for unique tag
        altest = alplib('get', al.tag);
        if length(altest) > 1
            varargout{1} = false;
            return;
        end

        % add record to lib and save
        alplibs = alplib('get');
        alplibs(end+1) = al; %#ok<NASGU>
        save(libfilename, 'alplibs');
        varargout{1} = true;

    case 'empty'
        % return an empty record array
        alplibs = struct('tag', {}, ...
            'classname', {}, ...
            'pseudoDLL', {}, ...
            'dllfile', {}, ...
            'protofile', {}, ...
            'protofunc', {}, ...
            'arch', {});
        varargout{1} = alplibs;

    case 'select'
        % interactively select one record
        alplibs = alplib('get');
        infostr = {};
        for ai = 1:length(alplibs)
            if alplibs(ai).pseudoDLL
                infostr{end+1} = sprintf('P %s (class: %s): %s', ...
                    alplibs(ai).tag, ...
                    alplibs(ai).classname, alplibs(ai).dllfile); %#ok<AGROW>
            else
                infostr{end+1} = sprintf('  %s (class: %s): %s', ...
                    alplibs(ai).tag, ...
                    alplibs(ai).classname, alplibs(ai).dllfile); %#ok<AGROW>
            end
        end
        if isempty(infostr)
            infostr{1} = 'No DLL installed';
            selection = 0;
        else
            selection = -1;
        end
        if nargin > 1
            promptstr = varargin{1};
        else
            promptstr = 'Please select API:';
        end
        [tempselection, ok] = listdlg('ListString', infostr, ...
            'SelectionMode', 'single', ...
            'Name', 'Please choose...', ...
            'PromptString', promptstr, ...
            'ListSize', [500, 150]);
        if selection == -1
            selection = tempselection;
        end
        varargout{1} = selection;
        varargout{2} = ok;
        if (ok ~= 0) && selection > 0 && length(alplibs) >= selection
            varargout{3} = alplibs(selection);
        else
            varargout{3} = [];
        end

end

end
