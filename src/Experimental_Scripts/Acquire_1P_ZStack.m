function Acquire_1P_ZStack(app, thickness, numslices, tag)
arguments
    app
    thickness
    numslices
    tag
end
Stage = app.getDevice("Scientifica_Stage_Controller");
cam = app.getDevice('Camera');
Shutters = app.getDevice('Shutter_Device');

%Checks if enable594 is ON
if Shutters(1, 4).State

else
    Shutters(1, 4).State = 1;
end


app.makeExperimentFolder(tag);
app.assignDevicesForMonitoring([cam, Stage]);
app.assignMasterDevice(cam);

dz = thickness / numslices;

Zstack1P = uint16(zeros(cam.ROI(4), cam.ROI(2), numslices));
Zstack1P_positions = zeros(3, numslices); %Records stage positions
for ii = 1:numslices

    Stage.Update_Current_Position_Microns();
    Zstack1P(:, :, ii) = cam.Snap();
    pause(0.05) % Pause to not saturate the COM
    Zstack1P_positions(:, ii) = [Stage.x; Stage.y; Stage.z];
    Stage.Step_Fixed(3, dz);

end

Shutters(1, 4).State = 0;
disp('Saving file')
save(strcat(app.expfolder, '\output.mat'), 'Zstack1P', 'Zstack1P_positions', '-v7.3')
disp('Experiment Done')
end

%%
%     Stage=xx.getDevice("Scientifica_Stage_Controller");
%     cam=xx.getDevice('Camera');
%     Stage.Update_Current_Position_Microns();
%     Stage.z

%%
%Acquire_1P_ZStack(app,thickness,numslices,tag)