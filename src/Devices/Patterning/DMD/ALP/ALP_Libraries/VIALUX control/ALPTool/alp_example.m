% ALP_EXAMPLE  some examples on how to use the classes and functions in this package
%              that provide access to the API functions developed by Vialux GmbH, Germany,
%              to control DMDs (digital micromirror devices)
%
% File information:
%   version 1.0 (feb 2014)
%   (c) Martin Vogel
%   email: matlab@martin-vogel.info
%
% Revision history:
%   1.0 (feb 2014) initial release version
%

%% ALP tool installation
alptoolinstall

%% interactively select and load api, then use it in alptool
alptool();

%% load specific DLL in pseudomode and use it in two instances of alptool
%tagname = 'tagname';
%alpapi = alpload(tagname, true);
%alptool(alpapi);
%alptool(alpapi);
