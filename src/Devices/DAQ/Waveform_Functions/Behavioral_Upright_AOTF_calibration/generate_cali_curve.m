%% type in the AOTF v-response curve measured from powermeter

v = [0.5, 1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5]; % AOTF488 voltage
output = [0.190000000000000, 0.840000000000000, 1.90000000000000, 3.40000000000000, 5, 6.50000000000000, 7.60000000000000, 8.10000000000000, 7.80000000000000, 7.50000000000000]; %mW, measured on 06/02/21
note = 'Behavioral Upright, AOTF voltage (V) vs.488 output (mW) response curve, determined on 06/02/21';

%% Fit: 'AU_AOTF_fit_010921'.
[xData, yData] = prepareCurveData(v, output);

% Set up fittype and options.
ft = fittype('smoothingspline');
opts = fitoptions('Method', 'SmoothingSpline');
opts.Normalize = 'on';
opts.SmoothingParam = 0.999907615543713;

% Fit model to data.
fitresult = fit(xData, yData, ft, opts);

% Plot fit with data.
figure('Name', 'AU_AOTF_fit_010921');
h = plot(fitresult, xData, yData);
legend(h, 'output vs. v', 'AU_AOTF_fit_010921', 'Location', 'NorthEast', 'Interpreter', 'none');
% Label axes
xlabel('v', 'Interpreter', 'none');
ylabel('output', 'Interpreter', 'none');
grid on

%%
AU_AOTF.fit = fitresult;

AU_AOTF.v = v;

AU_AOTF.output = output;


AU_AOTF.note = note;

save('BU_AOTF.mat', '-struct', 'AU_AOTF');