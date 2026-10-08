function feat = extract_yamnet_features(x,fs,net,alreadyPreprocessed)
%EXTRACT_YAMNET_FEATURES Frozen YAMNet embedding for one clip.
%
% The 1024-D global-average-pooling representation is extracted from every
% YAMNet patch and summarized using mean and standard deviation.
%
% Output dimension = 2048.
%
% alreadyPreprocessed=false (default):
%   Apply the common clean preprocessing internally.
%
% alreadyPreprocessed=true:
%   Use x exactly as provided. This option is intended for future
%   robustness experiments so MFCC and YAMNet can consume the exact same
%   perturbed waveform without a second peak-normalization step.

if nargin<4
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

% Ensure very short recordings can form at least one YAMNet patch.
minimumSamples=ceil(0.975*C.targetFs);
if numel(x)<minimumSamples
    x(end+1:minimumSamples,1)=0;
end

S=yamnetPreprocess(x,C.targetFs);

try
    Z=predict(net,S,Outputs=C.yamnet.embeddingLayer);
catch ME
    error("Could not extract YAMNet %s output. " + ...
        "Check your MATLAB/YAMNet version.\nOriginal error:\n%s", ...
        C.yamnet.embeddingLayer,ME.message);
end

if isa(Z,"dlarray")
    Z=extractdata(Z);
end

Z=gather(Z);
Z=squeeze(Z);

% Convert to [patches x 1024].
if isvector(Z)
    Z=reshape(Z,1,[]);
elseif size(Z,1)==C.yamnet.embeddingDimension
    Z=Z.';
elseif size(Z,2)~=C.yamnet.embeddingDimension
    Z=reshape(Z,C.yamnet.embeddingDimension,[]).';
end

assert(size(Z,2)==C.yamnet.embeddingDimension, ...
    "Unexpected YAMNet embedding dimension: %d",size(Z,2));

feat=[mean(Z,1),std(Z,0,1)];
feat(~isfinite(feat))=0;
end
