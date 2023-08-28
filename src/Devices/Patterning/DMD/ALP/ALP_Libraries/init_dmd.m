function [api, device] = init_dmd(api_version)
% initialize the DMD if needed
% api_version: string, the class of api to load. Should be either,
%   'alpV42x64' or 'alpV43x64'
if ~isa(api_version, 'char')
    error('api_version should be a string')
end

switch api_version
    case 'alpV42x64'
        if ~exist('api', 'var') || ~isa(api, 'alpV42x64')
            api = alpload('alpV42x64');
        end
    case 'alpV43x64'
        if ~exist('api', 'var') || ~isa(api, 'alpV43x64')
            api = alpload('alpV43x64');
        end
    otherwise
        error(['unknown api_version :', api_version])
end
% connects to device, resets connection if there already was one
device = alpdevice(api);
alloc_val = device.alloc;
switch alloc_val
    case api.DEFAULT
        % pass
    case api.NOT_ONLINE
        error 'dmd device not online'
    otherwise
        error(['dmd device alloc returned ', num2str(alloc_val)])
end

end
