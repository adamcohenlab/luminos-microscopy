function success = Autofocus(app, range)

% Use to autofocus stage within range given by user. The assumption is that 
% the correct focal plane is within +-range of current position. Designed for 
% Luminos Advanced Imaging tab multi-round acquisition.

% Currently hardcoded to work with camera 1.

tic;
success = 0;
cam = app.getDevice("Camera");
dq_session = app.getDevice("DAQ");

% Check for stages
warning('off');
stage = app.getDevice("Linear1D_Controller");
if isempty(stage)
   stage = app.getDevice("Linear_Controller");
   if isempty(stage) || length(fieldnames(stage.pos)) < 3
        error("No suitable stages detected. Aborting autofocus.");
   else
        posz = stage.pos.z;
        posx = stage.pos.x;
        posy = stage.pos.y;
   end
else
    posz = stage.pos.zAbs;
    posx = 0.025;
    posy = 0.001;
end
warning('on');

pos_max = posz + range;
pos_min = posz - range;

% Load autofocus setup json from folder if present, otherwise just use
% current settings
scriptDir = pwd;
jsonFolder = fullfile(scriptDir, 'src', 'User_Interface', 'relay', 'data');
jsonFiles = dir(fullfile(jsonFolder, '*.json'));
autofocusFile = ''; 
for k = 1:length(jsonFiles)
    if contains(jsonFiles(k).name, 'Autofocus', 'IgnoreCase', true)
        autofocusFile = fullfile(jsonFolder, jsonFiles(k).name);
        break; 
    end
end
if isempty(autofocusFile)
    disp('No JSON file for Autofocus found.');
    data = [];
else
    jsonText = fileread(autofocusFile);
    data = jsondecode(jsonText);
end

% Set AO and DO according to autofocus json
if ~isempty(data) && (dq_session.waveforms_built == true)
    for i = 1:numel(data.analogOutputs)
        taskAO(i) = DQ_AO_On_Demand(0, dq_session.remove_al(data.analogOutputs(i).port));
        if strcmp(data.analogOutputs(i).fcn, 'constant') % Ignore non-constant waveforms
            taskAO(i).OD_Write(str2double(data.analogOutputs(i).fcn_args.value));
        end
    end
    for i = 1:numel(data.digitalOutputs)
        taskDO(i) = DQ_DO_On_Demand(0, dq_session.remove_al(data.digitalOutputs(i).port));
        if strcmp(data.digitalOutputs(i).fcn, 'constant') % Ignore non-constant waveforms
            taskDO(i).OD_Write(str2double(data.digitalOutputs(i).fcn_args.value));
        end
    end
end

% Scan through positions between +- range and find best by brightness
% percentile. Rough scan first.
best = 0;
for position = pos_min:(pos_max-pos_min)/10:pos_max
    stage.Move_To_Position([posx, posy, position]);
    im = cam(1).Snap();
    fft(:,:) = abs(fft2(double(im(:,:))));
    
    fftx = squeeze(mean(fft,2));
    
    perc = mean(fftx(round(end*0.95):round(end),:),1);
    %perc = prctile(double(im),99.9,"all");
    if perc > best
        best_pos = position;
        best = perc;
    end
end

% Go to best position from first scan and scan around it.
best = 0;
for position = linspace(best_pos - range/10, best_pos + range/10, 10)
    stage.Move_To_Position([posx, posy, position]);
    im = cam(1).Snap();
    fft(:,:) = abs(fft2(double(im(:,:))));

    fftx = squeeze(mean(fft,2));
    
    perc = mean(fftx(round(end*0.95):round(end),:),1);
    %perc = prctile(double(im),99.99,"all");
    if perc > best
        best_pos = position;
        best = perc;
    end
end

% Go to optimal position and diplay result.
stage.Move_To_Position([posx, posy, best_pos]);
disp("Best position found: " + best_pos + ".");

success = 1;

% Reset AO and DO values to 0
if exist('taskAO') && dq_session.waveforms_built == true
    for i = 1:size(taskAO,2)
        taskAO(i).OD_Write(0);
        taskAO(i).ClearTask();
    end
end
if exist('taskDO') && dq_session.waveforms_built == true
    for i = 1:size(taskDO,2)
        taskDO(i).OD_Write(0);
        taskDO(i).ClearTask();
    end
end

toc;

end


% Earlier attempt at gradient descent. 

% step = range/10;
% threshold = 0.1;
% iterations = 0;
% figure;
% grad = 1;
% 
% while iterations < 40
% iterations = iterations + 1;
% img(:,:,1) = img(:,:,2);
% stage.Move_To_Position([stage.pos.x, stage.pos.y, stage.pos.z + grad * step]);
% img(:,:,2) = cam(1).Snap();
% 
% % fft(:,:,1) = abs(fft2(double(img(:,:,1))));
% % fft(:,:,2) = abs(fft2(double(img(:,:,2))));
% % 
% % fftx = squeeze(mean(fft,2));
% % 
% % hf = mean(fftx(round(end*0.95):round(end),:),1);
% %mf = mean(fftx(round(end*0.45):round(end*0.55),:),1);
% 
% % grad = -(hf(2)-hf(1))/(hf(2)+hf(1))*10;
% perc = prctile(double(img),99.999,[1,2]);
% grad = -(perc(2)-perc(1))/(perc(2)+perc(1))*5
% 
% gs = sign(grad);
% grad = gs * min(abs(grad),1);% * min(log(iterations),1) + grad_init * max(1-log(iterations),0)  ;
% %mean_grad = mean_grad + grad/30;
% plot(iterations, perc(2),'o-', 'Color','r');
% hold on;
% plot(iterations, perc(1), 'o-', 'Color', 'b');
% plot(iterations, grad*1e5, 'o-', 'Color', 'g');
% end