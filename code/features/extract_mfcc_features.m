function feat = extract_mfcc_features(x,fs,alreadyPreprocessed)
%EXTRACT_MFCC_FEATURES Fixed-length handcrafted DSP representation.
%
% Frame-level:
%   13 MFCC coefficients + first-order deltas
%
% Clip-level summary:
%   mean, standard deviation, median, Q25, Q75
%
% Output dimension:
%   (13 + 13) * 5 = 130
%
% alreadyPreprocessed=false (default):
%   Apply the common clean preprocessing internally.
%
% alreadyPreprocessed=true:
%   Use x exactly as provided. This option is intended for future
%   robustness experiments so a controlled perturbed waveform is not
%   peak-normalized again after the perturbation has been applied.

if nargin<3
    alreadyPreprocessed=false;
end

C=config();

if ~alreadyPreprocessed
    x=preprocess_audio(x,fs,C.targetFs);
    fs=C.targetFs;
else
    x=double(x(:));
    x(~isfinite(x))=0;
    assert(fs==C.targetFs, ...
        "Preprocessed input must already be at targetFs=%d Hz.",C.targetFs);
end

winLength=round(C.mfcc.frameMs/1000*C.targetFs);
hopLength=round(C.mfcc.hopMs/1000*C.targetFs);
overlapLength=winLength-hopLength;

if numel(x)<winLength
    x(end+1:winLength,1)=0;
end

M=mfcc(x,C.targetFs, ...
    "Window",hann(winLength,"periodic"), ...
    "OverlapLength",overlapLength, ...
    "NumCoeffs",C.mfcc.numCoeffs);

D=[zeros(1,size(M,2));diff(M,1,1)];
F=[M D];

feat=[ ...
    mean(F,1), ...
    std(F,0,1), ...
    median(F,1), ...
    prctile(F,25,1), ...
    prctile(F,75,1)];

feat(~isfinite(feat))=0;
end
