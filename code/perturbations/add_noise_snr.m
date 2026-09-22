function y = add_noise_snr(x,snrDb,seed)
%ADD_NOISE_SNR Controlled additive Gaussian noise at a target SNR.
%
% IMPORTANT FOR FUTURE EXPERIMENTS:
% Generate the perturbed waveform once, then use that SAME waveform for
% both MFCC and YAMNet feature extraction.

if nargin<3
    seed=42;
end

rng(seed);

x=double(x(:));
noise=randn(size(x));

signalPower=mean(x.^2);
noisePower=mean(noise.^2);

targetNoisePower=signalPower/(10^(snrDb/10));
noise=noise*sqrt(targetNoisePower/max(noisePower,eps));

y=x+noise;
end
