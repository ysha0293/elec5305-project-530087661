function [X,Y,folds] = build_mfcc_cache(meta,P)
%BUILD_MFCC_CACHE Extract MFCC features once and cache them.

cacheFile=fullfile(P.cacheDir,"mfcc_features.mat");

if isfile(cacheFile)
    S=load(cacheFile,"X","Y","folds");
    X=S.X;
    Y=S.Y;
    folds=S.folds;
    fprintf("Loaded MFCC feature cache.\n");
    return;
end

n=height(meta);
probe=extract_mfcc_features(zeros(16000,1),16000);

X=zeros(n,numel(probe),'single');
Y=meta.label;
folds=meta.fold;

fprintf("\nExtracting MFCC features...\n");

for i=1:n
    [x,fs]=audioread(meta.filePath(i));
    X(i,:)=single(extract_mfcc_features(x,fs));

    if mod(i,250)==0 || i==n
        fprintf("MFCC: %d/%d\n",i,n);
    end
end

save(cacheFile,"X","Y","folds","-v7.3");
end
