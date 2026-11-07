function bank = load_or_train_clean_fold_models(Xclean,Y,folds,methodName,P,clipID)
%LOAD_OR_TRAIN_CLEAN_FOLD_MODELS Load clean SVMs saved by the clean benchmark.
%
% Normal path: run_official_10fold_svm trains each clean-fold SVM while
% computing the clean benchmark and saves the exact models here. Robustness
% therefore only loads/reuses them.
%
% Safety fallback: if the bank is missing (for example clean benchmark was
% intentionally skipped), rebuild it from CLEAN features only.

C = config();
methodTag = regexprep(lower(string(methodName)),"[^a-z0-9]+","_");
cacheFile = fullfile(P.cacheDir,methodTag+"_clean_fold_models.mat");
clipID = string(clipID(:));
featureFingerprint=[size(Xclean,1),size(Xclean,2),sum(double(Xclean(:))),sum(double(Xclean(:)).^2)];

if isfile(cacheFile)
    S = load(cacheFile,"bank");
    if isfield(S,"bank") && isfield(S.bank,"cacheVersion") && ...
            string(S.bank.cacheVersion)==C.cache.robustnessVersion && ...
            isfield(S.bank,"featureFingerprint") && isequal(S.bank.featureFingerprint,featureFingerprint) && ...
            isequal(string(S.bank.clipID),clipID)
        bank = S.bank;
        % Backward-compatible audit metadata enrichment; no retraining.
        if ~isfield(bank,"trainClipID") || ~isfield(bank,"testClipID")
            bank.trainClipID=cell(10,1); bank.testClipID=cell(10,1);
            for ff=1:10
                bank.trainClipID{ff}=clipID(folds~=ff);
                bank.testClipID{ff}=clipID(folds==ff);
            end
            bank.trainedFromCleanOnly=true;
            bank.normalizationFromTrainingOnly=true;
            save(cacheFile,"bank","-v7.3");
        end
        fprintf("Loaded cached %s clean-fold model bank.\n",methodName);
        return;
    end
end

fprintf("Clean model bank missing; rebuilding %s bank from CLEAN features only...\n",methodName);
bank = struct();
bank.method = string(methodName);
bank.cacheVersion = C.cache.robustnessVersion;
bank.clipID = clipID;
bank.featureFingerprint = featureFingerprint;
bank.folds = folds(:);
bank.models = cell(10,1);
bank.mu = cell(10,1);
bank.sigma = cell(10,1);
bank.trainClipID = cell(10,1);
bank.testClipID = cell(10,1);
bank.trainedFromCleanOnly = true;
bank.normalizationFromTrainingOnly = true;

for f=1:10
    idxTrain = folds~=f;
    idxTest = folds==f;
    assert(~any(idxTrain & idxTest),"Train/test overlap detected.");

    Xtr = double(Xclean(idxTrain,:));
    Ytr = Y(idxTrain);
    mu = mean(Xtr,1);
    sigma = std(Xtr,0,1);
    sigma(sigma<1e-12)=1;
    Xtr = (Xtr-mu)./sigma;

    learner = templateSVM("KernelFunction",C.svm.kernel, ...
        "BoxConstraint",C.svm.boxConstraint,"Standardize",false);
    model = fitcecoc(Xtr,Ytr,"Learners",learner,"Coding",C.svm.coding);

    bank.models{f}=model;
    bank.mu{f}=mu;
    bank.sigma{f}=sigma;
    bank.trainClipID{f}=clipID(idxTrain);
    bank.testClipID{f}=clipID(idxTest);
end

save(cacheFile,"bank","-v7.3");
end
