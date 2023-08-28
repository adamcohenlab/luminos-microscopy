function string = rig
% rig identifies a computer in the dmd initialization code.
%
% Instructions:
% - Find this file in
%       X:\Lab\Computer Code\General Matlab\VIALUX control\
% - Add this folder with subfolders to the matlab path.
% - Copy the file rig_template.m to your computer desktop folder.
% - Rename the file in your computer rig_template.m -> rig.m
% - Edit the first line of code and change 'firefly' to other unique word.
% - Cut and paste the file rig.m in your computer into the folder
%       C:\Program Files\MATLAB\R2014a\toolbox\local\
%     or equivalent in your computer.
% - Edit the file lab_init_device.m and add a case for your computer
% - listo! The path should be set correctly after restarting matlab.
%
% 2016 Vicente Parot
% Cohen Lab - Harvard University
localstring = 'firefly';
if nargout
    string = localstring;
else
    disp(localstring)
end
end