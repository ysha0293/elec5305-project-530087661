function y = add_noise_snr(x,snrDb,seed)
%ADD_NOISE_SNR Controlled additive Gaussian noise at a target SNR.
%
% The noise generator uses a local deterministic stream so the same clip,
% SNR and seed reproduce exactly the same perturbation without changing
% MATLAB's global RNG state.
%
% IMPORTANT FOR ROBUSTNESS EXPERIMENTS:
% Generate the perturbed waveform once, then use that SAME waveform for
% both MFCC and YAMNet feature extraction.

if nargin<3
    seed=42;
end

stream = RandStream("mt19937ar","Seed",double(seed));

x=double(x(:));
noise=randn(stream,size(x));

signalPower=mean(x.^2);
noisePower=mean(noise.^2);

targetNoisePower=signalPower/(10^(snrDb/10));
noise=noise*sqrt(targetNoisePower/max(noisePower,eps));

y=x+noise;
end
