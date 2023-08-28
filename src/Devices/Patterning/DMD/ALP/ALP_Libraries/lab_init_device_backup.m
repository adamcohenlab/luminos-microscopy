%% initialize DMD

% 2016 Vicente Parot
% Cohen Lab - Harvard University

% loads library if needed
assert(~ ~exist('rig', 'file'), 'no rig')
switch rig
    case 'upright'
        if ~exist('api', 'var') || ~isa(api, 'alpV42x64')
            api = alpload('alpV42x64');
        end
    case {'firefly', 'adaptive'}
        if ~exist('api', 'var') || ~isa(api, 'alpV43x64')
            api = alpload('alpV43x64');
        end
    otherwise
        error 'unknown rig'
end
% connects to device, resets connection if there already was one
device = alpdevice(api);
alloc_val = device.alloc;
switch alloc_val
    case api.DEFAULT
        disp 'device alloc ok'
    case api.NOT_ONLINE
        disp 'device not online'
    otherwise
        display(['device alloc returned ', num2str(alloc_val)])
end
