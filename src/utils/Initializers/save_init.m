% This writes a Rig_Init object to a JSON file

function saved_as_json = save_init(obj, outputFilePath, options)
arguments
    obj
    outputFilePath(1, 1) string
    options.InitName(1, 1) string = "Rig_Init"
end
try
    % Convert the object to a struct so it can be jsonencoded properly
    structObj = object2struct(obj);

    % Json encode the struct
    jsonStr = jsonencode(structObj);

    % Open the file for writing
    fileID = fopen(outputFilePath, 'w');

    % Check if the file was opened successfully
    if fileID == -1
        error('Error opening the output file. Please check the file path.');
    end

    % Write the JSON string to the file
    fwrite(fileID, jsonStr, 'char');

    % Close the file
    fclose(fileID);

    % use prettier to format the JSON file nicely
    prettier_cmd = sprintf('prettier --write "%s"', outputFilePath);
    [status, cmdout] = system(prettier_cmd);
    saved_as_json = true;

catch
    % fallback to saving as a .mat file
    warning('Error saving %s file as JSON. Saving as .mat file instead.', options.InitName);

    % swap to .mat extension
    [pathstr, name, ext] = fileparts(outputFilePath);
    outputFilePath = fullfile(sprintf('%s.mat', name));

    % save as .mat file with object named options.InitName
    eval(sprintf('%s = obj;', options.InitName));
    save(outputFilePath, options.InitName);
    saved_as_json = false;
end
end