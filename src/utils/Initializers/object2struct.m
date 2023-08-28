% Convert an object to a struct. This function is useful for saving objects
function s = object2struct(obj)
if isempty(obj) && class(obj) ~= "string" && class(obj) ~= "char" % if string, we want to show "" instead of []
    s = [];
    % if the object is an array of objects, convert each object to a struct
elseif numel(obj) > 1 && isobject(obj(1))
    s = arrayfun(@(x) object2struct(x), obj, 'UniformOutput', false);
elseif iscell(obj)
    s = cell(size(obj));
    for i = 1:numel(obj)
        s{i} = object2struct(obj{i});
    end
elseif isa(obj, 'string')
    s = char(obj);
elseif isobject(obj)
    props = properties(obj);
    s = struct();
    for i = 1:numel(props)
        propName = props{i};
        subObj = obj.(propName);
        s.(propName) = object2struct(subObj);
    end
    % add a field to indicate the class of the object if deviceType does not exist
    if ~isfield(s, 'deviceType')
        s.objectType = class(obj);
    end

    % reorder properties so that "objectType" or "deviceType" is the first field, and "name" is the second field
    if isfield(s, 'name')
        s = reorder_fields(s, 'name');
    end
    if isfield(s, 'objectType')
        s = reorder_fields(s, 'objectType');
    elseif isfield(s, 'deviceType')
        s = reorder_fields(s, 'deviceType');
    end
else
    s = obj;
end
end

function s = reorder_fields(s, firstField)
fieldOrder = [{firstField}, setdiff(fieldnames(s), firstField, 'stable')'];
s = orderfields(s, fieldOrder);
end