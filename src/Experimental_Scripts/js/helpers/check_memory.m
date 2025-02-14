function check_memory(app)

    % Get drive information
    [drive, ~, ~] = fileparts(app.datafolder);
    drive = extractBefore(drive, '\');
    drive = drive + "\";
    fileObj = java.io.File(drive);
    freeSpace = fileObj.getFreeSpace(); % in bytes
    totalSpace = fileObj.getTotalSpace(); % in bytes

    % Calculate amount of requested data for .bin files
    reqSpace = 0;
    cam = app.getDevice('Camera');
    for i = 1:numel(cam)
        reqSpace = reqSpace + double(cam(i).ROI(2)*cam(i).ROI(4))*cam(i).frames_requested*2; %in bytes
    end
    if reqSpace > freeSpace
        error("Not enough memory for recording. Free up space on " + drive + " drive.");
    elseif freeSpace < totalSpace*0.05
        warning(drive + " drive almost full. " + freeSpace/(1024^3) + " GB or " + round(freeSpace/totalSpace*100) + "% remaining.");
    end

end