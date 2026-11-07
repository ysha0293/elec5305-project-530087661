function [y,info] = add_environmental_noise_snr(x,fs,noiseFile,snrDb,seed)
%ADD_ENVIRONMENTAL_NOISE_SNR Add an external environmental recording at target SNR.
%
% x must already be the common preprocessed clean waveform at targetFs.
% The chosen noise-file segment is deterministic for a fixed seed.

C = config();
assert(fs==C.targetFs,"Input must already be at targetFs=%d Hz.",C.targetFs);

x = double(x(:));
[n,noiseFs] = audioread(noiseFile);
if size(n,2)>1
    n = mean(n,2);
end
n = double(n(:));
n(~isfinite(n)) = 0;
if noiseFs ~= fs
    n = resample(n,fs,noiseFs);
end
n = n - mean(n);

if isempty(n) || mean(n.^2) < eps
    error("Noise file contains no usable signal: %s",noiseFile);
end

% Deterministic file segment. Tile if the source is shorter than the clip.
stream = RandStream("mt19937ar","Seed",double(seed));
L = numel(x);
if numel(n) < L
    repeatCount = ceil((L+numel(n))/numel(n));
    n = repmat(n,repeatCount,1);
end
maxStart = numel(n)-L+1;
if maxStart > 1
    startIndex = randi(stream,maxStart);
else
    startIndex = 1;
end
noiseSegment = n(startIndex:startIndex+L-1);
noiseSegment = noiseSegment - mean(noiseSegment);

signalPower = mean(x.^2);
noisePower = mean(noiseSegment.^2);
if signalPower < eps
    y = x;
    scale = 0;
else
    targetNoisePower = signalPower/(10^(double(snrDb)/10));
    scale = sqrt(targetNoisePower/max(noisePower,eps));
    y = x + scale*noiseSegment;
end

% Verify achieved SNR numerically (before any optional clipping; none is used).
added = y-x;
achieved = 10*log10(max(mean(x.^2),eps)/max(mean(added.^2),eps));

info.noiseFile = string(noiseFile);
info.seed = double(seed);
info.startIndex = double(startIndex);
info.scale = double(scale);
info.targetSNRdB = double(snrDb);
info.achievedSNRdB = double(achieved);
if signalPower>=eps
    assert(abs(achieved-double(snrDb))<1e-8, ...
        "Achieved SNR differs from target: target %.6f dB, achieved %.6f dB",snrDb,achieved);
end
end
