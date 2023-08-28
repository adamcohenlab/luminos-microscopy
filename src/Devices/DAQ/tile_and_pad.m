function outy = tile_and_pad(iny, t, finalval)
%TILE_AND_CUT:This is a helper function for the Waveform_Functions to fit
%them into a predefined timevector
totsamps = numel(t);
outy = repmat(iny, [1, floor(totsamps/numel(iny))]);
outy = [outy, zeros(1, totsamps-numel(outy)) + finalval];
outy(end) = finalval;
end
