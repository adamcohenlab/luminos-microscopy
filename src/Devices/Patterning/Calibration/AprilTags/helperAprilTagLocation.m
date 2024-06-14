%Return location of AprilTag files
function path = helperAprilTagLocation()
    [path,~] = fileparts(mfilename("fullpath"));
end