% alptoolinstall  script to register ALP DLLs with api classes
%
% File information:
%   version 1.0 (feb 2014)
%   (c) Martin Vogel
%   email: matlab@martin-vogel.info
%
% Revision history:
%   1.0 (feb 2014) initial release version

%% (1) DLLs already installed in this package?
if alplib('exist')
    % overwrite?
    if strcmp(questdlg('Overwrite ALP DLL registration?', 'Please answer', 'yes', 'no', 'no'), 'yes')
        alplib('delete');
    end
end

%% (2) show list of installed DLLs
[selection, ok] = alplib('select', 'OK to add another ALP API:');
if ok == 0
    clear selection ok;
    return;
end
clear selection ok;

%% (3) query DLLs and save information
while true
    if strcmp(questdlg('Register pseudo DLL?', 'Please answer', 'yes', 'no', 'no'), 'yes')

        pseudoDLL = true;
        dllfile = '';

    else

        pseudoDLL = false;

        % search for DLL file
        [dllFileName, dllPathName] = uigetfile('*.dll', 'Please select DLL file...');
        if isnumeric(dllFileName) && (dllFileName == 0)
            clear dllFileName dllPathName pseudoDLL;
            return;
        end
        dllfile = [dllPathName, dllFileName];
        clear dllFileName dllPathName;

    end

    % query type of interface
    [interface, ok] = listdlg('ListString', {'V1 32bit', 'V4.2 32bit', 'V4.2 64bit', 'V4.3 64bit'}, ...
        'SelectionMode', 'single', ...
        'Name', 'Please choose API type...', ...
        'PromptString', 'Available ALP API classes:');
    if ok == 0
        clear interface ok;
        clear dllfile pseudoDLL;
        return
    end
    clear ok;

    switch interface
        case 1
            classname = 'alpV1x32';
            protofile = 'alpV1x32proto.m';
            protofunc = @alpV1x32proto;
            arch = 'win32';

        case 2
            classname = 'alpV42x32';
            protofile = 'alpV42x32proto.m';
            protofunc = @alpV42x32proto;
            arch = 'win32';

        case 3
            classname = 'alpV42x64';
            protofile = 'alpV42x64proto.m';
            protofunc = @alpV42x64proto;
            arch = 'win64';
        case 4
            classname = 'alpV43x64';
            protofile = 'alpV43x64proto.m';
            protofunc = @alpV43x64proto;
            arch = 'win64';
    end
    clear interface;

    % ask for tag name
    tagname = classname;
    answer = inputdlg('API tag name:', 'Please enter...', 1, {tagname});
    if isempty(answer)
        clear dllfile pseudoDLL tagname classname protofile protofunc arch;
        clear answer;
        return;
    else
        tagname = answer{1};
        clear answer;
    end

    % and save to alplibs DB
    if ~alplib('set', 'tag', tagname, 'classname', classname, ...
            'dllfile', dllfile, 'pseudoDLL', pseudoDLL, 'protofile', protofile, ...
            'protofunc', protofunc, 'arch', arch)
        msgbox('ALP API lib can not be saved', 'Error', 'error');
        clear dllfile pseudoDLL tagname classname protofile protofunc arch;
        return;
    end
    clear dllfile pseudoDLL tagname classname protofile protofunc arch;

    if strcmp(questdlg('Register another DLL?', 'Please answer', 'yes', 'no', 'no'), 'yes')
        continue;
    else
        return;
    end
end
