function [X,Y,folds,clipID,filePath] = build_mfcc_cache(meta,P)
%BUILD_MFCC_CACHE Extract MFCC features once and cache them.
%
% Clip identifiers and paths are stored with the feature matrix so future
% clean/perturbed representation pairs can be matched unambiguously.

C=config();
cacheFile=fullfile(P.cacheDir,"mfcc_features.mat");

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
        fprintf("Loaded MFCC feature cache (%s).\n",C.cache.version);
        return;
    elseif all(isfield(S,{"X","Y","folds"})) && size(S.X,1)==height(meta)
        % Upgrade a legacy v2 cache without recomputing the features.
        X=S.X;
        Y=S.Y;
        folds=S.folds;
        clipID=string(meta.slice_file_name);
        filePath=string(meta.filePath);

        cacheInfo=struct();
        cacheInfo.version=C.cache.version;
        cacheInfo.method="MFCC";
        cacheInfo.targetFs=C.targetFs;
        cacheInfo.numCoeffs=C.mfcc.numCoeffs;
        cacheInfo.frameMs=C.mfcc.frameMs;
        cacheInfo.hopMs=C.mfcc.hopMs;
        cacheInfo.summaryStatistics=C.mfcc.summaryStatistics;

        save(cacheFile,"X","Y","folds","clipID","filePath","cacheInfo","-v7.3");
        fprintf("Upgraded legacy MFCC cache with clip IDs and reproducibility metadata.\n");
        return;
    else
        fprintf("MFCC cache is incompatible with the current metadata. Rebuilding...\n");
    end
end

n=height(meta);
probe=extract_mfcc_features(zeros(16000,1),16000);

X=zeros(n,numel(probe),'single');
Y=meta.label;
folds=meta.fold;
clipID=string(meta.slice_file_name);
filePath=string(meta.filePath);

fprintf("\nExtracting MFCC features...\n");

for i=1:n
    [x,fs]=audioread(meta.filePath(i));
    X(i,:)=single(extract_mfcc_features(x,fs));

    if mod(i,250)==0 || i==n
        fprintf("MFCC: %d/%d\n",i,n);
    end
end

cacheInfo=struct();
cacheInfo.version=C.cache.version;
cacheInfo.method="MFCC";
cacheInfo.targetFs=C.targetFs;
cacheInfo.numCoeffs=C.mfcc.numCoeffs;
cacheInfo.frameMs=C.mfcc.frameMs;
cacheInfo.hopMs=C.mfcc.hopMs;
cacheInfo.summaryStatistics=C.mfcc.summaryStatistics;

save(cacheFile,"X","Y","folds","clipID","filePath","cacheInfo","-v7.3");
end
