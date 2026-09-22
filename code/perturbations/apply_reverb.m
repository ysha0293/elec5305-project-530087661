function y = apply_reverb(x,rir)
%APPLY_REVERB Convolve audio with a room impulse response.
%
% Exact mild/moderate/strong RIR conditions will be configured during the
% reverberation stage.

x=double(x(:));
rir=double(rir(:));

y=fftfilt(rir,x);
end
