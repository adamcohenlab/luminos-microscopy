function Acquire_Hadamard_ZStack_Triggered(app, varargin)
% arguments
%     thickness
%     numslices
%     tag

thickness = varargin{1};
numslices = varargin{2};
tag = string(varargin{3});


Stage = app.getDevice("Newport_Motor_Controller"); % on FF
cam = app.getDevice('Camera');
dmd = app.getDevice('DMD'); %dmd(1,1) is the ALP on FF
daq = app.getDevice('DAQ');

app.makeExperimentFolder(tag);
%app.assignDevicesForMonitoring([cam, Stage]);
%app.assignMasterDevice(cam);

% Calculate z step
numslices = round(numslices);
dz = thickness / numslices;

% Find current position and move to starting position
origin = Stage.Get_Current_Position(); % Original position in mm

if numslices ~= 1
    Stage.moveToRel(thickness/2);
    Stage.Move_To_Position([0, 0, origin + thickness/2]);
    previous_position = Stage.Get_Current_Position() + dz;
else
    previous_position = origin + dz; % If a single slice is requested don't move, take Hadamard of current slice. Ignore thickness
end

% Check if center (origin) is included or not
% if ~isinteger(numslices/2)
%     add_center = false;
% else
%     add_center = true;
% end

pause(0.1)

for ii = 1:numslices
    
    ztarget = previous_position - dz;
    Stage.Move_To_Position([0, 0, ztarget]);
    pause(0.1);
    
    Hadamard_ZStack_positions(ii) = Stage.Get_Current_Position();
    
    Generate_Hadamard(app);
    if (~daq.Build_Waveforms())
        throw("Building waveforms failed.");
    end
    
    foldertag = tag + Hadamard_ZStack_positions(ii);
    Waveform_Camera_Sync_Acquisition_tags(app, 1,foldertag);
    
    % wait until done
    while ~app.exp_complete
        pause(0.5);
    end
    
    previous_position = Hadamard_ZStack_positions(ii);
    Stage.moveToRel(-dz);
    pause(0.1);
    
    
end

% Return to origin
Stage.Move_To_Position([0, 0, origin]);


end

