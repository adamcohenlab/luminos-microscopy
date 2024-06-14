function [phase_vec, xoffset, two_pi_pk_loc] = Diff_Data_to_Phase(Diffraction_Data_Raw, options)
arguments
    Diffraction_Data_Raw
    options.pk_separation = 50;
end
Diffraction_Data = Diffraction_Data_Raw;
Diffraction_Data = Diffraction_Data - min(Diffraction_Data);
[PKS, pk_locs] = findpeaks(Diffraction_Data, 'MinPeakHeight', max(Diffraction_Data)*.9, 'MinPeakDistance', options.pk_separation);
pi_pk_loc = min(pk_locs);
xoffset = max(find(Diffraction_Data < (.05 * max(Diffraction_Data)) & (1:256) < pi_pk_loc));
Diffraction_Data = Diffraction_Data(xoffset:end);
bg_sub_diff_data = Diffraction_Data - min(Diffraction_Data);
[PKS, pk_locs] = findpeaks(bg_sub_diff_data, 'MinPeakHeight', max(bg_sub_diff_data)*.9, 'MinPeakDistance', options.pk_separation);
pi_pk_loc = min(pk_locs);
[PKS, min_locs] = findpeaks(-bg_sub_diff_data, 'MinPeakHeight', max([-.8 * max(bg_sub_diff_data), -bg_sub_diff_data(end)]), 'MinPeakDistance', options.pk_separation);
if ~isempty(min_locs) && ~isempty(pi_pk_loc) && min(min_locs) < numel(bg_sub_diff_data)
    two_pi_pk_loc = min(min_locs(min_locs > pi_pk_loc+20));
else
    two_pi_pk_loc = [];
end

norm_diff_data = bg_sub_diff_data / max(bg_sub_diff_data);
phase_vec = zeros(size(norm_diff_data));
sin_sol = 2 * asin(sqrt(norm_diff_data));
phase_vec(1:pi_pk_loc) = sin_sol(1:pi_pk_loc);
if isempty(two_pi_pk_loc)
    %phase_vec(pi_pk_loc+1:end)=2*pi-sin_sol(pi_pk_loc+1:end);
    two_pi_pk_loc = numel(phase_vec);
end
seg2_norm_diff_data = (Diffraction_Data(pi_pk_loc+1:two_pi_pk_loc) - Diffraction_Data(two_pi_pk_loc)) / (Diffraction_Data(pi_pk_loc) - Diffraction_Data(two_pi_pk_loc));
seg2_sinsol = 2 * asin(sqrt(seg2_norm_diff_data));
phase_vec(pi_pk_loc+1:two_pi_pk_loc) = 2 * pi - seg2_sinsol;
phase_vec(two_pi_pk_loc+1:end) = [];
end