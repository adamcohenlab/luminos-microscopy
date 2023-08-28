img = xx.DMD_Tab.pd.Target;
stackImgs = addPieSlices(img, 24, 1, 'interleaved', 250);
%stackImgs=addDonutSeries(img,1,3,'interleaved',250);
xx.DMD_Tab.pd.pattern_stack = stackImgs;

% playmov(stackImgs,1)

%%
xx.DMD_Tab.pd.Target = oldStacks(:, :, 1) + oldStacks(:, :, 2);
oldStacks = xx.DMD_Tab.pd.pattern_stack;

%%
newStacks = zeros(1024, 768, 5);
newStacks(:, :, 2) = oldStacks(:, :, 1);
newStacks(:, :, 3) = oldStacks(:, :, 1) + oldStacks(:, :, 2);
newStacks(:, :, 5) = [];
newStacks = logical(newStacks);

%%
newStacks = RoundRobin(oldStacks, 'inh', 0.6);
xx.DMD_Tab.pd.pattern_stack = newStacks;

%% center-donut hysteresis
img = xx.DMD_Tab.pd.Target;
stackImgs = hysteresis_donutRamp(img, 10, 1, 200);
xx.DMD_Tab.pd.pattern_stack = stackImgs;

%% 2-cell hysteresis
clear oldStacks newStacks
oldStacks = xx.DMD_Tab.pd.pattern_stack;
newStacks = hysteresis_2cell(oldStacks(:, :, 1), oldStacks(:, :, 2), 10, 2);
xx.DMD_Tab.pd.pattern_stack = newStacks;

%% ex rounb robin for PV
clear oldStacks newStacks
oldStacks = xx.DMD_Tab.pd.pattern_stack;
newStacks = RoundRobin_ext_ramp_PV(oldStacks);
%clicky(double(newStacks));
xx.DMD_Tab.pd.pattern_stack = newStacks;

%%

%% inhibitory round robin
clear oldStacks newStacks
oldStacks = xx.DMD_Tab.pd.pattern_stack;
n_rois = size(oldStacks, 3);
holdings = [0.05, 0.02, 0.15, 0.3];
newStacks = RoundRobin_inh_ramp(oldStacks, holdings);
xx.DMD_Tab.pd.pattern_stack = newStacks;

playmov(newStacks)

%% multiCell-rheobase
clear oldStacks newStacks
oldStacks = xx.DMD_Tab.pd.pattern_stack;
newStacks = multiCell_rheobase(oldStacks);
xx.DMD_Tab.pd.pattern_stack = newStacks;


%playmov(newStacks)

% %% mapping connectivity_pulses
% clear newStacks
% newStacks=conn_map_pulse(oldStacks);
% xx.DMD_Tab.pd.pattern_stack=newStacks;
clicky(double(newStacks))

%% mapping connectivity_ramp
clear newStacks
holdings = [0.2, 0.2];
peaks = [0.8, 1];
newStacks = conn_map_ramp(oldStacks, holdings, peaks);
xx.DMD_Tab.pd.pattern_stack = newStacks;
%clicky(double(newStacks))

%% flip-flop
clear newStacks
holdings = [0.3, 0.05];
newStacks = flipflop(oldStacks, holdings);
xx.DMD_Tab.pd.pattern_stack = newStacks;
clicky(double(newStacks))

%% flip-flop reverse
clear newStacks
oldStacks2(:, :, 1) = oldStacks(:, :, 2);
oldStacks2(:, :, 2) = oldStacks(:, :, 1);
holdings2(1) = holdings(2);
holdings2(2) = holdings(1);
newStacks = flipflop(oldStacks2, holdings2);
xx.DMD_Tab.pd.pattern_stack = newStacks;
clicky(double(newStacks))