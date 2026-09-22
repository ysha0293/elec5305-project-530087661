function feat = extract_yamnet_features(x,fs,net)
%EXTRACT_YAMNET_FEATURES Frozen YAMNet embedding for one clip.
%
% The 1024-D global-average-pooling representation is extracted from every
% YAMNet patch and summarized using mean and standard deviation.
%
% Output dimension = 2048.

C=config();
x=preprocess_audio(x,fs,C.targetFs);

% Ensure very short recordings can form at least one YAMNet patch.
minimumSamples=ceil(0.975*C.targetFs);
if numel(x)<minimumSamples
    x(end+1:minimumSamples,1)=0;
end

S=yamnetPreprocess(x,C.targetFs);

try
    Z=predict(net,S,Outputs="global_average_pooling2d");
catch ME
    error("Could not extract YAMNet global_average_pooling2d output. " + ...
        "Check your MATLAB/YAMNet version.\nOriginal error:\n%s",ME.message);
end

if isa(Z,"dlarray")
    Z=extractdata(Z);
end

Z=gather(Z);
Z=squeeze(Z);

% Convert to [patches x 1024].
if isvector(Z)
    Z=reshape(Z,1,[]);
elseif size(Z,1)==1024
    Z=Z.';
elseif size(Z,2)~=1024
    Z=reshape(Z,1024,[]).';
end

assert(size(Z,2)==1024, ...
    "Unexpected YAMNet embedding dimension: %d",size(Z,2));

feat=[mean(Z,1),std(Z,0,1)];
feat(~isfinite(feat))=0;
end
