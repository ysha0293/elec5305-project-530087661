function x = preprocess_audio(x,fs,targetFs)
%PREPROCESS_AUDIO Common preprocessing shared by MFCC and YAMNet.
%
% 1) Convert stereo/multichannel to mono.
% 2) Replace non-finite samples.
% 3) Resample to a common sample rate.
% 4) Remove DC.
% 5) Peak-normalize.
%
% Using the same waveform preprocessing helps keep the representation type
% as the main controlled variable.

if size(x,2)>1
    x = mean(x,2);
end

x = double(x(:));
x(~isfinite(x)) = 0;

if fs ~= targetFs
    x = resample(x,targetFs,fs);
end

x = x - mean(x);

peak = max(abs(x));
if peak>0
    x = x/peak;
end
end
