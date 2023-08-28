% This sript adds all subfolders to path

try
    bp = load('breakpoints.mat');
    dbstop(bp.bp);
catch
end
folder = fileparts(which(mfilename));
addpath(genpath(folder));
[~, ~] = system(sprintf("Setx MatlabDir ""%s""", matlabroot));

% clear the folder variable
clear folder