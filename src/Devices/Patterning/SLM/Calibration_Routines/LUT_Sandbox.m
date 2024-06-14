Blanked_Lut_Mat = zeros(4, 256, 1500);
on_samples = LUTMat(:, :, 2:2:end);
indexvec = 1:1500;
for i = 1:4
    Blanked_Lut_Mat(i, :, any(mod(indexvec-126, 16) == ([0:3]' + (i - 1) * 4))) = on_samples(i, :, any(mod(indexvec-126, 16) == ([0:3]' + (i - 1) * 4)));
end

%%
Composite_Mat = squeeze(sum(Blanked_Lut_Mat, 1));
phase_mat = zeros(207, 16);

%%
figure
phase_ax = gca;
for i = 1:32
    phase_vec{i} = Diff_Data_to_Phase(sumdata(i, :));
    plot(phase_ax, phase_vec{i})
    hold(phase_ax, 'on')

end
