%% multiCell-rheobase
clear oldStacks newStacks
oldStacks = xx.DMD_Tab.pd.pattern_stack;
newStacks = multiCell_rheobase(oldStacks);
xx.DMD_Tab.pd.pattern_stack = newStacks;


%playmov(newStacks)

clicky(double(newStacks))

%% mapping connectivity_ramp
clear newStacks
holdings = [0.3, 0.15];
newStacks = RoundRobin_ext_L1(oldStacks, holdings);
xx.DMD_Tab.pd.pattern_stack = newStacks;
clicky(double(newStacks))

%% flip-flop
clear newStacks
holdings = [0.3, 0.2];
newStacks = flipflop(oldStacks, holdings, 2, 8);
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