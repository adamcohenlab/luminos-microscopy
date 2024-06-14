% Function to load a rig init JSON file and convert it to a MATLAB Rig_Initializer object
function init = load_init(fileName)
% File path will be obtained by which function
filePath = which(fileName);
if exist(filePath, 'file')
    % Read the contents of the JSON file
    jsonStr = fileread(filePath);

    % Decode the JSON data
    jsonData = jsondecode(jsonStr);

    % Convert the struct to MATLAB objects
    init = struct2object(jsonData);
else
    warning('JSON file does not exist. Falling back to .mat initializer.')
    % if the json file doesn't exist, fallback to the .mat initializer
    [path, name, ext] = fileparts(filePath);
    matFilePath = fullfile(path, [char(name), '.mat']);

    % check if the .mat file exists
    if ~exist(matFilePath, 'file')
        error('Neither .json nor .mat initializer exists. Check spelling')
    end

    init_mat = load(matFilePath);
    field_names = fieldnames(init_mat);
    init = eval(['init_mat.', field_names{1}]);
end
end

% Function to recursively convert the struct to MATLAB objects
function obj = struct2object(s)
if isstruct(s)
    genericStruct = false;
    if isfield(s, 'deviceType')
        % execute {deviceType}_Initializer() to create the object
        try
            obj = eval([s.deviceType, '_Initializer()']);
        catch
            error(['Unknown deviceType: ', s.deviceType]);
        end
    elseif isfield(s, 'objectType')
        obj = eval(s.objectType);
    else
        % otherwise create a generic struct
        obj = struct();
        genericStruct = true;
    end

    props = fieldnames(s);
    for i = 1:numel(props)
        propName = props{i};

        % Skip the objectType property
        if strcmp(propName, 'objectType')
            continue;
        
        % Skip if the property is not writable (but if it's a generic struct, everything is writable)
        elseif ~genericStruct && ~is_writable(propName, obj)
            continue;
        end

        subStruct = s.(propName);
        if ~isempty(subStruct)
            obj.(propName) = struct2object(subStruct);
        end
    end
elseif iscell(s)
    obj = {};
    for i = 1:numel(s)
        obj{end+1} = struct2object(s{i});
    end
    % try to cast to array, if possible (if all elements are the same type)
    try
        obj = [obj{:}];
    catch
    end
% cast char arrays to strings (because matlab concatenates char arrays into a single string)
elseif ischar(s)
    obj = string(s);
else
    obj = s;
end
end

% check if the property is writable by checking Set_Access of the metaclass of the object
function out = is_writable(prop, obj)
    mc = metaclass(obj);
    prop_meta = mc.PropertyList(strcmp({mc.PropertyList.Name}, prop));
    
    % Check if the property exists on the object
    if isempty(prop_meta)
        error(['Unknown property: ', prop]);
    end
    
    out = strcmp(prop_meta.SetAccess, 'public');
end
    