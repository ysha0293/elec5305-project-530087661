function [X,Y,folds,clipID,filePath] = build_yamnet_cache(meta,P)
%BUILD_YAMNET_CACHE Extract frozen YAMNet embeddings once and cache them.
%
% Clip identifiers and paths are stored with the feature matrix so future
% clean/perturbed representation pairs can be matched unambiguously.

C=config();
cacheFile=fullfile(P.cacheDir,"yamnet_embeddings.mat");

if isfile(cacheFile)
    S=load(cacheFile);
    required=["X","Y","folds","clipID","filePath","cacheInfo"];
    if all(isfield(S,cellstr(required))) && ...
            string(S.cacheInfo.version)==C.cache.version
        X=S.X;
        Y=S.Y;
        folds=S.folds;
        clipID=S.clipID;
        filePath=S.filePath;
        fprintf("Loaded YAMNet feature cache (%s).\n",C.cache.version);
        return;
    elseif all(isfield(S,{"X","Y","folds"})) && size(S.X,1)==height(meta)
        % Upgrade a legacy v2 cache without recomputing the embeddings.
        X=S.X;
        Y=S.Y;
        folds=S.folds;
        clipID=string(meta.slice_file_name);
        filePath=string(meta.filePath);

        cacheInfo=struct();
        cacheInfo.version=C.cache.version;
        cacheInfo.method="YAMNet";
        cacheInfo.modelName=C.yamnet.modelName;
        cacheInfo.embeddingLayer=C.yamnet.embeddingLayer;
        cacheInfo.embeddingDimension=C.yamnet.embeddingDimension;
        cacheInfo.targetFs=C.targetFs;
        cacheInfo.modelSource="legacy v2 cache";
        cacheInfo.downloadURL=C.yamnet.downloadURL;

        save(cacheFile,"X","Y","folds","clipID","filePath","cacheInfo","-v7.3");
        fprintf("Upgraded legacy YAMNet cache with clip IDs and reproducibility metadata.\n");
        return;
    else
        fprintf("YAMNet cache is incompatible with the current metadata. Rebuilding...\n");
    end
end

fprintf("\nLoading pretrained YAMNet...\n");
[net,~,modelInfo]=load_yamnet_model();
fprintf("YAMNet source: %s\n",modelInfo.source);

n=height(meta);
X=zeros(n,2*C.yamnet.embeddingDimension,'single');
Y=meta.label;
folds=meta.fold;
clipID=string(meta.slice_file_name);
filePath=string(meta.filePath);

fprintf("Extracting frozen YAMNet embeddings...\n");

for i=1:n
    [x,fs]=audioread(meta.filePath(i));
    X(i,:)=single(extract_yamnet_features(x,fs,net));

    if mod(i,100)==0 || i==n
        fprintf("YAMNet: %d/%d\n",i,n);
    end
end

cacheInfo=struct();
cacheInfo.version=C.cache.version;
cacheInfo.method="YAMNet";
cacheInfo.modelName=C.yamnet.modelName;
cacheInfo.embeddingLayer=C.yamnet.embeddingLayer;
cacheInfo.embeddingDimension=C.yamnet.embeddingDimension;
cacheInfo.targetFs=C.targetFs;
cacheInfo.modelSource=modelInfo.source;
cacheInfo.downloadURL=C.yamnet.downloadURL;

save(cacheFile,"X","Y","folds","clipID","filePath","cacheInfo","-v7.3");
end
