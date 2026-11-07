function R = run_official_10fold_svm(X,Y,folds,methodName,P,clipID)
%RUN_OFFICIAL_10FOLD_SVM Official UrbanSound8K clean 10-fold evaluation.
% Normalization and SVM fitting use training folds only.
%
% IMPORTANT: the clean SVMs trained here are saved as a reusable model bank.
% The later robustness stage therefore reuses these exact clean-trained models
% instead of fitting the same SVMs a second time.

C=config();
if nargin<6 || isempty(clipID), clipID="row_"+string((1:size(X,1))'); else, clipID=string(clipID(:)); end
assert(size(X,1)==numel(Y) && numel(Y)==numel(folds) && numel(clipID)==numel(Y),"Clean inputs are misaligned.");
assert(isequal(sort(unique(folds))',(1:10)),"Official folds must be exactly 1..10.");

classOrder=categories(Y); nClasses=numel(classOrder);
Fold=(1:10)'; Accuracy=zeros(10,1); MacroF1=zeros(10,1);
PerClassRecall=zeros(10,nClasses); PerClassF1=zeros(10,nClasses); AggregateConfusion=zeros(nClasses,nClasses);
allClipID=strings(0,1); allTrue=strings(0,1); allPred=strings(0,1); allCorrect=false(0,1); allFold=zeros(0,1);

% Build the exact clean model bank while computing the clean benchmark.
% This avoids any duplicate SVM fitting during robustness evaluation.
methodTag = regexprep(lower(string(methodName)),"[^a-z0-9]+","_");
cacheFile = fullfile(P.cacheDir,methodTag+"_clean_fold_models.mat");
featureFingerprint=[size(X,1),size(X,2),sum(double(X(:))),sum(double(X(:)).^2)];
bank=struct();
bank.method=string(methodName);
bank.cacheVersion=C.cache.robustnessVersion;
bank.clipID=clipID;
bank.featureFingerprint=featureFingerprint;
bank.folds=folds(:);
bank.models=cell(10,1);
bank.mu=cell(10,1);
bank.sigma=cell(10,1);
bank.trainClipID=cell(10,1);
bank.testClipID=cell(10,1);
bank.trainedFromCleanOnly=true;
bank.normalizationFromTrainingOnly=true;

for f=1:10
    fprintf("\n[%s] Official fold %d/10\n",methodName,f);
    idxTest=folds==f; idxTrain=~idxTest;
    assert(~any(idxTrain & idxTest),"Train/test overlap detected in official fold %d.",f);

    Xtr=double(X(idxTrain,:)); Xte=double(X(idxTest,:)); Ytr=Y(idxTrain); Yte=Y(idxTest);
    mu=mean(Xtr,1); sigma=std(Xtr,0,1); sigma(sigma<1e-12)=1;
    Xtr=(Xtr-mu)./sigma; Xte=(Xte-mu)./sigma;
    learner=templateSVM("KernelFunction",C.svm.kernel,"BoxConstraint",C.svm.boxConstraint,"Standardize",false);
    model=fitcecoc(Xtr,Ytr,"Learners",learner,"Coding",C.svm.coding);

    % Save the SAME clean-trained model and training-only normalization that
    % produced the clean benchmark result for this official held-out fold.
    bank.models{f}=model;
    bank.mu{f}=mu;
    bank.sigma{f}=sigma;
    bank.trainClipID{f}=clipID(idxTrain);
    bank.testClipID{f}=clipID(idxTest);

    yPred=predict(model,Xte); M=evaluate_predictions(Yte,yPred,classOrder);
    Accuracy(f)=M.accuracy; MacroF1(f)=M.macroF1; PerClassRecall(f,:)=M.recall(:)'; PerClassF1(f,:)=M.f1(:)';
    AggregateConfusion=AggregateConfusion+M.confusion;
    currentTrue=string(Yte); currentPred=string(yPred);
    allClipID=[allClipID;clipID(idxTest)]; allTrue=[allTrue;currentTrue]; allPred=[allPred;currentPred]; %#ok<AGROW>
    allCorrect=[allCorrect;currentTrue==currentPred]; allFold=[allFold;repmat(f,nnz(idxTest),1)]; %#ok<AGROW>
    fprintf("Accuracy : %.2f %%\n",100*M.accuracy); fprintf("Macro-F1: %.4f\n",M.macroF1);
end

% Save once after all ten clean folds are complete. Robustness evaluation
% subsequently loads this bank; it does not refit the SVMs.
save(cacheFile,"bank","-v7.3");
fprintf("Saved %s clean-fold model bank from clean benchmark.\n",methodName);

FoldMetrics=table(Fold,Accuracy,MacroF1);
Summary=table(string(methodName),mean(Accuracy),std(Accuracy),mean(MacroF1),std(MacroF1), ...
    'VariableNames',{'Method','MeanAccuracy','StdAccuracy','MeanMacroF1','StdMacroF1'});
ClassMetrics=table(string(classOrder),mean(PerClassRecall,1)',std(PerClassRecall,0,1)', ...
    mean(PerClassF1,1)',std(PerClassF1,0,1)','VariableNames',{'Class','MeanRecall','StdRecall','MeanF1','StdF1'});
Predictions=table(allClipID,allFold,allTrue,allPred,allCorrect, ...
    'VariableNames',{'ClipID','Fold','TrueLabel','PredictedLabel','Correct'});

writetable(FoldMetrics,fullfile(P.tableDir,lower(methodName)+"_fold_metrics.csv"));
writetable(Summary,fullfile(P.tableDir,lower(methodName)+"_summary.csv"));
writetable(ClassMetrics,fullfile(P.tableDir,lower(methodName)+"_per_class_metrics.csv"));
AggTable=array2table(AggregateConfusion,"VariableNames",matlab.lang.makeValidName(classOrder),"RowNames",classOrder);
writetable(AggTable,fullfile(P.tableDir,lower(methodName)+"_aggregate_confusion.csv"),"WriteRowNames",true);
plot_confusion_matrix(AggregateConfusion,classOrder,methodName+" - Aggregate Out-of-Fold Confusion Matrix", ...
    fullfile(P.figureDir,lower(methodName)+"_aggregate_confusion.png"));

R.method=string(methodName); R.foldMetrics=FoldMetrics; R.summary=Summary; R.classMetrics=ClassMetrics;
R.aggregateConfusion=AggregateConfusion; R.classOrder=classOrder; R.predictions=Predictions;
end
