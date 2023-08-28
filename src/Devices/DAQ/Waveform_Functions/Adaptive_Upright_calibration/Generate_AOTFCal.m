function Generate_AOTFCal(aotfcaldata, options)

%% type in the AOTF v-response curve measured from powermeter
arguments
    aotfcaldata
    options.area = [];
end
if ~isempty(options.area)
    output = aotfcaldata(:, 2) / options.area;
else
    output = aotfcaldata(:, 1);
end
v = aotfcaldata(:, 1);
note = 'Adaptive Upright, AOTF voltage (V) vs. 488 nm output (mW) response curve, determined on 05/05/22. refpatch2. Areaincluded cm^2. INVERSEFIT.';

%% Fit: 'AU_AOTF_fit_010921'.
[xData, yData] = prepareCurveData(output, v);

% Set up fittype and options.
ft = fittype('smoothingspline');
opts = fitoptions('Method', 'SmoothingSpline');
opts.Normalize = 'on';
opts.SmoothingParam = .999999;

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

save('AU_AOTF_Inverse.mat', '-struct', 'AU_AOTF');
end
