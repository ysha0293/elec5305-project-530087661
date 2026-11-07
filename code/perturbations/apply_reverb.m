function y = apply_reverb(x,rir)
%APPLY_REVERB Convolve a preprocessed waveform with a fixed RIR.
%
% Output is cropped to the original clip length so clean and perturbed
% representations correspond to the same nominal recording duration.

x = double(x(:));
rir = double(rir(:));
assert(~isempty(rir),"RIR must not be empty.");

fullY = fftfilt(rir,x);
y = fullY(1:numel(x));
y(~isfinite(y)) = 0;
end
