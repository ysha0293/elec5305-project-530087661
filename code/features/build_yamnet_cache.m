function [X,Y,folds] = build_yamnet_cache(meta,P)
%BUILD_YAMNET_CACHE Extract frozen YAMNet embeddings once and cache them.

cacheFile=fullfile(P.cacheDir,"yamnet_embeddings.mat");

if isfile(cacheFile)
    S=load(cacheFile,"X","Y","folds");
    X=S.X;
    Y=S.Y;
    folds=S.folds;
    fprintf("Loaded YAMNet feature cache.\n");
    return;
end

fprintf("\nLoading pretrained YAMNet...\n");
[net,~]=audioPretrainedNetwork("yamnet");

n=height(meta);
X=zeros(n,2048,'single');
Y=meta.label;
folds=meta.fold;

fprintf("Extracting frozen YAMNet embeddings...\n");

for i=1:n
    [x,fs]=audioread(meta.filePath(i));
    X(i,:)=single(extract_yamnet_features(x,fs,net));

    if mod(i,100)==0 || i==n
        fprintf("YAMNet: %d/%d\n",i,n);
    end
end

save(cacheFile,"X","Y","folds","-v7.3");
end
