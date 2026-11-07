function rir = build_synthetic_rir(fs,rt60Seconds,durationSeconds,directToReverbDb,seed)
%BUILD_SYNTHETIC_RIR Deterministic controlled room impulse response.
%
% The late reverberant tail follows an exponential amplitude envelope that
% decays by 60 dB over approximately RT60. A few fixed early reflections
% are included. The RIR is L2-normalized so the experiment mainly changes
% temporal smearing rather than arbitrary overall gain.

assert(rt60Seconds>0 && durationSeconds>0,"RT60 and duration must be positive.");
L = max(2,round(durationSeconds*fs));
t = (0:L-1)'/fs;
stream = RandStream("mt19937ar","Seed",double(seed));

% Diffuse late tail: amplitude reaches 10^-3 at t = RT60.
envelope = 10.^(-3*t/rt60Seconds);
tail = randn(stream,L,1).*envelope;
tail(1) = 0;

% Suppress the first few milliseconds of the diffuse tail.
preDelay = round(0.005*fs);
tail(1:min(preDelay,L)) = 0;

% Fixed deterministic early reflections.
early = zeros(L,1);
delaysMs = [12 23 37 53];
gains = [0.55 0.38 0.27 0.18];
for k=1:numel(delaysMs)
    idx = 1+round(delaysMs(k)*1e-3*fs);
    if idx<=L
        early(idx) = gains(k);
    end
end

reverbPart = early + 0.15*tail;
reverbRms = sqrt(sum(reverbPart.^2));
if reverbRms>0
    reverbPart = reverbPart/reverbRms;
end

directGain = 10^(directToReverbDb/20);
rir = reverbPart;
rir(1) = rir(1)+directGain;
rir = rir/max(norm(rir),eps);
end
