function Generate_WFM_CalCurve(expfolder, device_name, options)

%% type in the AOTF v-response curve measured from powermeter
arguments
    expfolder
    device_name
    options.inverse = false;
    options.area = [];
end
load(fullfile(expfolder, 'output_data.mat'));
caldata = Device_Data{2}.calibration_curve';
if ~isempty(options.area)
    output = caldata(:, 2) / options.area;
else
    output = caldata(:, 2);
end
output = output - min(output);
v = caldata(:, 1);

%% Fit: 'Cal_Out_fit_010921'.
if options.inverse
    [xData, yData] = prepareCurveData(output, v);
else
    [xData, yData] = prepareCurveData(v, output);
end
note = '';
% Set up fittype and options.
ft = fittype('smoothingspline');
opts = fitoptions('Method', 'SmoothingSpline');
opts.Normalize = 'on';
opts.SmoothingParam = .9999999999;

% Fit model to data.
fitresult = fit(xData, yData, ft, opts);

% Plot fit with data.
figure('Name', 'Cal_Out_fit_010921');
h = plot(fitresult, xData, yData);
legend(h, 'output vs. v', 'Cal_Out_fit_010921', 'Location', 'NorthEast', 'Interpreter', 'none');
% Label axes
xlabel('v', 'Interpreter', 'none');
ylabel('output', 'Interpreter', 'none');
grid on

%%
Cal_Out.fit = fitresult;

Cal_Out.v = v;

Cal_Out.output = output;


Cal_Out.note = note;
if options.inverse
    save(strcat(device_name, '_Cal_Out_Inverse.mat'), '-struct', 'Cal_Out');
else
    save(strcat(device_name, '_Cal_Out.mat'), '-struct', 'Cal_Out');
end
end
