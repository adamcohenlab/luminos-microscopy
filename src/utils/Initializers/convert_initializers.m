% Convert all .mat files in the current directory to .json files

init_name = 'Rig_Init'; % could change to Rig_Init

% Define the current directory
currentDir = pwd;

% Find all .mat files in the directory and its subdirectories
fileList = dir(fullfile(currentDir, '/**/*.mat'));

% Loop through each .mat file
for i = 1:length(fileList)
    % Get the name of the current file
    fileName = fileList(i).name;

    % Load the data from the .mat file
    matData = load(fullfile(fileList(i).folder, fileName));

    % Define the name of the new file
    newFileName = strrep(fileName, '.mat', '.json');

    try
        % Convert the data to a JSON string
        saved_as_json = save_init(matData.(init_name), newFileName, 'InitName', init_name);

        if ~saved_as_json
            disp(['File not converted: ', fileName]);
        else
            % Display a message indicating the file has been converted
            disp(['File converted: ', fileName]);
        end
    catch me
        % Display a message indicating the file could not be converted
        disp(['File not converted: ', fileName]);
        warning(me.message)
    end
end