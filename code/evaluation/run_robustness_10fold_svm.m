function R = run_robustness_10fold_svm(Xclean,Xperturbed,Y,folds,methodName,family,severity,P,clipID)
%RUN_ROBUSTNESS_10FOLD_SVM Strict clean-train / perturbed-test evaluator.
%
% SVM fitting and normalization are based ONLY on clean training folds.
% Perturbed features are used only for prediction on the held-out fold.

C = config();
if nargin<9 || isempty(clipID)
    clipID = "row_"+string((1:size(Xclean,1))');
else
    clipID = string(clipID(:));
end

assert(isequal(size(Xclean),size(Xperturbed)),"Clean and perturbed matrices must have identical size.");
assert(size(Xclean,1)==numel(Y) && numel(Y)==numel(folds),"Feature rows, labels and folds must align.");
assert(numel(clipID)==numel(Y),"clipID must align with observations.");
assert(C.robustness.trainOnCleanOnly && C.robustness.useOfficialFoldsOnly,"Robustness protocol configuration is invalid.");
assert(isequal(sort(unique(folds))',(1:10)),"Expected exactly official UrbanSound8K folds 1..10.");

classOrder = categories(Y); nClasses=numel(classOrder);
Fold=(1:10)'; Accuracy=zeros(10,1); MacroF1=zeros(10,1);
PerClassRecall=zeros(10,nClasses); PerClassF1=zeros(10,nClasses);
AggregateConfusion=zeros(nClasses,nClasses);
allClipID=strings(0,1); allTrue=strings(0,1); allPred=strings(0,1);
allCorrect=false(0,1); allFold=zeros(0,1);

% Clean model bank is trained once and cached. Every perturbation reuses it.
bank = load_or_train_clean_fold_models(Xclean,Y,folds,methodName,P,clipID);

for f=1:10
    idxTest=folds==f; idxTrain=~idxTest;
    assert(~any(idxTrain & idxTest) && nnz(idxTest)>0 && nnz(idxTrain)>0,"Invalid train/test split.");

    Xte=double(Xperturbed(idxTest,:)); Yte=Y(idxTest);
    Xte=(Xte-bank.mu{f})./bank.sigma{f};
    yPred=predict(bank.models{f},Xte);
    M=evaluate_predictions(Yte,yPred,classOrder);

    Accuracy(f)=M.accuracy; MacroF1(f)=M.macroF1;
    PerClassRecall(f,:)=M.recall(:)'; PerClassF1(f,:)=M.f1(:)';
    AggregateConfusion=AggregateConfusion+M.confusion;

    currentTrue=string(Yte); currentPred=string(yPred);
    allClipID=[allClipID;clipID(idxTest)]; %#ok<AGROW>
    allTrue=[allTrue;currentTrue]; %#ok<AGROW>
    allPred=[allPred;currentPred]; %#ok<AGROW>
    allCorrect=[allCorrect;currentTrue==currentPred]; %#ok<AGROW>
    allFold=[allFold;repmat(f,nnz(idxTest),1)]; %#ok<AGROW>
end

FoldMetrics=table(Fold,Accuracy,MacroF1);
Summary=table(string(methodName),string(family),string(severity), ...
    mean(Accuracy),std(Accuracy),mean(MacroF1),std(MacroF1), ...
    'VariableNames',{'Method','Perturbation','Severity','MeanAccuracy','StdAccuracy','MeanMacroF1','StdMacroF1'});
ClassMetrics=table(string(classOrder),mean(PerClassRecall,1)',std(PerClassRecall,0,1)', ...
    mean(PerClassF1,1)',std(PerClassF1,0,1)', ...
    'VariableNames',{'Class','MeanRecall','StdRecall','MeanF1','StdF1'});
Predictions=table(allClipID,allFold,allTrue,allPred,allCorrect, ...
    repmat(string(family),numel(allFold),1),repmat(string(severity),numel(allFold),1), ...
    'VariableNames',{'ClipID','Fold','TrueLabel','PredictedLabel','Correct','Perturbation','Severity'});

R.method=string(methodName); R.family=string(family); R.severity=string(severity);
R.foldMetrics=FoldMetrics; R.summary=Summary; R.classMetrics=ClassMetrics;
R.aggregateConfusion=AggregateConfusion; R.classOrder=classOrder; R.predictions=Predictions;

% Small condition-level outputs only. No clip-level predictions or large MAT here.
outDir=condition_output_dir(P,family,severity);
methodTag=regexprep(lower(string(methodName)),"[^a-z0-9]+","_");
writetable(FoldMetrics,fullfile(outDir,methodTag+"_fold_metrics.csv"));
writetable(Summary,fullfile(outDir,methodTag+"_summary.csv"));
writetable(ClassMetrics,fullfile(outDir,methodTag+"_per_class_metrics.csv"));

if C.storage.keepClipLevelPredictionFiles
    writetable(Predictions,fullfile(P.workRobustnessDir,methodTag+"_"+family+"_"+severity+"_predictions.csv"));
end
end
