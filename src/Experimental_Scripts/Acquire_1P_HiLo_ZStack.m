function Acquire_1P_HiLo_ZStack(app, thickness, numslices, tag, Pattern)
arguments
    app
    thickness
    numslices
    tag
    Pattern
end
Stage = app.getDevice("Scientifica_Stage_Controller");
cam = app.getDevice('Camera');
dmd = app.getDevice('DMD'); %dmd(1,1) is the ALP for the Behavior
Shutters = app.getDevice('Shutter_Device');

cam = cam(1, 2);
%Checks if enable594 is ON
if Shutters(1, 4).State

else
    Shutters(1, 4).State = 1;
end

app.makeExperimentFolder(tag);
app.assignDevicesForMonitoring([cam, Stage]);
app.assignMasterDevice(cam);

dz = thickness / numslices;

Zstack1P = uint16(zeros(cam.ROI(4), cam.ROI(2), 2*numslices));
Zstack1P_positions = zeros(3, numslices); %Records stage positions
[x, y] = meshgrid(1:768, 1:1024);

% Initialize dmd
dmd(1, 1).Write_White(); %Project Widefield

counter = 1;
for ii = 1:numslices

    Stage.Update_Current_Position_Microns();


    dmd(1, 1).Write_White(); %Project Widefield

    pause(cam.exposuretime+0.1) % DMD takes a bit to refresh

    Zstack1P(:, :, counter) = cam.Snap();
    counter = counter + 1;


    % Project speckle
    if Pattern == 1
        dmd(1, 1).Target = round(rand(1024, 768));
        dmd(1, 1).Write_Static();
    else %pattern is an inclined stripe
        dmd(1, 1).Target = (sin(1.11*(x + y)) + 1) / 2;
        dmd(1, 1).Write_Static();
    end

    pause(cam.exposuretime+0.1) % Pause to not saturate the COM
    Zstack1P(:, :, counter) = cam.Snap();

    Zstack1P_positions(:, ii) = [Stage.x; Stage.y; Stage.z];
    counter = counter + 1;

    Stage.Step_Fixed(3, dz);


end

Shutters(1, 4).State = 0;

output{1} = Zstack1P_positions;
output{2} = size(Zstack1P);

disp('Saving file')
tic
save(strcat(app.expfolder, '\output.mat'), 'output', '-v7.3')
fileID = fopen(strcat(app.expfolder, '\frames.bin'), 'w');
fwrite(fileID, Zstack1P, 'uint16');
fclose(fileID);
toc
disp('Experiment Done')
end

% %% Acquire_1P_HiLo_ZStack(xx,100,10,'testHiLo')
%     Stage=xx.getDevice("Scientifica_Stage_Controller");
%     cam=xx.getDevice('Camera');
%      Stage.Update_Current_Position_Microns();
%      Stage.z
