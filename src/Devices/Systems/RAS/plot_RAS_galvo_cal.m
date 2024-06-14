function [pup, pdown] = plot_RAS_galvo_cal(PD_V, galvo_fb, upax, downax, pkseparationV)

dircheckerf = smooth(diff(smooth(galvo_fb)) > 0) > .5;
galvo_fb_up = galvo_fb(dircheckerf == 1);
[sorted_galvofb_up, Iup] = sort(galvo_fb_up);
PD_up = PD_V(dircheckerf == 1);
g = findgroups(sorted_galvofb_up);
sorted_galvofb_up = unique(sorted_galvofb_up);
unique_up = splitapply(@median, PD_up(Iup), g);
smoothup = smoothdata(unique_up, 'gaussian', .002, 'SamplePoints', sorted_galvofb_up);

galvo_fb_down = galvo_fb(dircheckerf == 0);
[sorted_galvofb_down, Idown] = sort(galvo_fb_down);
PD_down = PD_V(dircheckerf == 0);
g = findgroups(sorted_galvofb_down);
sorted_galvofb_down = unique(sorted_galvofb_down);
unique_down = splitapply(@mean, PD_down(Idown), g);
smoothdown = smoothdata(unique_down, 'gaussian', .002, 'SamplePoints', sorted_galvofb_down);

pdown = Peakfinder_Plot([sorted_galvofb_down(:)'; smoothdown(:)'], downax, 256, 'peakseparation', pkseparationV);
pup = Peakfinder_Plot([sorted_galvofb_up(:)'; smoothup(:)'], upax, 256, 'peakseparation', pkseparationV);

end