% This script adds all subfolders to path
folder = fileparts(which(mfilename));
addpath(genpath(folder));
[~, ~] = system(sprintf("Setx MatlabDir ""%s""", matlabroot));

% clear the folder variable
clear folder