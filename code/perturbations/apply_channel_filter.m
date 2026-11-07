function y = apply_channel_filter(x,fs,lowHz,highHz,filterOrder)
%APPLY_CHANNEL_FILTER Deterministic zero-phase band-limiting perturbation.

if nargin<5
    filterOrder = 8;
end
assert(lowHz>0 && highHz<fs/2 && lowHz<highHz, ...
    "Require 0 < lowHz < highHz < Nyquist.");

d = designfilt("bandpassiir", ...
    "FilterOrder",filterOrder, ...
    "HalfPowerFrequency1",lowHz, ...
    "HalfPowerFrequency2",highHz, ...
    "SampleRate",fs);

y = filtfilt(d,double(x(:)));
y(~isfinite(y)) = 0;
end
