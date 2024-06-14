%% This script will rebuild all of the binary libraries in the main .sln file.

%% It will also install necessary javascript libraries and create the javascript build folder.

% optionally allow just js rebuild (bypass c) or just c rebuild (bypass js)

function build(options)
arguments
    options.rebuild_c(1, 1) logical = true
    options.rebuild_js(1, 1) logical = true
end

current_path = fileparts(mfilename('fullpath'));

solution_path = fullfile(current_path,'src\lib\Luminos_MEX_VS\Luminos_MEX_VS.sln');
vs_path = 'C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE';
rebuild_command_c = ['Set PATH=', vs_path, ';%PATH% ', '&& devenv ', '"', solution_path, '"', ' ', '/Rebuild  Debug'];
build_command_c = ['Set PATH=', vs_path, ';%PATH% ', '&& devenv ', '"', solution_path, '"', ' ', '/Build  Debug'];

js_path = fullfile(current_path, "src", "User_Interface");
frontend_path = char(fullfile(js_path, "frontend"));
relay_path = char(fullfile(js_path, "relay"));
js_packages = 'concurrently prettier';

install_command_js = ['cd ', frontend_path, ' && npm install', ' && cd ', relay_path, ' && npm install && npm install -g ', js_packages];

if options.rebuild_js
    % Build js libraries
    fprintf("Installing javascript libraries...\n")
    [~, result] = system(install_command_js);
    display(result);
end

%If the JS install shows output describing existing vulnerabilities, they
%may by repaired by running (>npm audit fix) from the shell in the frontend
%and relay directories.

if options.rebuild_c
    % Build C++ libraries
    fprintf("Building C++ libraries...\n")
    system(rebuild_command_c);
    [~, result]=system(build_command_c); %Run twice to avoid annoying dependency issue
    display(result);
end
startup;
end
