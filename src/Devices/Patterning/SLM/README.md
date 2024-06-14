# Spatial Light Modulator Control Code

This folder contains all the code and libraries necessary for controlling the SLMs in the Cohen Lab. Create issues or open pull requests using Github for any discovered bugs or desired features.

###### Documentation
Contains detailed user guides for the controller.

###### SLM_Device.m
Defines the SLM_Device class.

###### Transform_Cal.m
Calculates the affine tranformation matrix to transform camera coordinates to equivalent SLM coordinates.

###### InitializeSDK.m
Helper function to initialize the SLM hardware and load the Meadowlark SDK.

###### Example_Parameter_Files
Examples for formatting the input parameter files that load rig-specific information into the polymorphic SLM_Device object. The actual parameter files will be in a separate folder for the actual release, but these will remain to aid code development. If you add a feature that requires a configuration file, please add a dummy example of the configuration file to this folder.

###### Meadowlark_SDK
Library files for the Meadowlark SDK.
