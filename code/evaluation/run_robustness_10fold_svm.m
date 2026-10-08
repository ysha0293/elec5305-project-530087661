function R = run_robustness_10fold_svm(Xclean,Xperturbed,Y,folds,methodName,conditionName,P,clipID)
%RUN_ROBUSTNESS_10FOLD_SVM Future-ready controlled robustness evaluator.
%
% This function encodes the teacher-recommended experiment exactly:
%
%   TRAIN: clean representations from the nine training folds
%   TEST : perturbed representations from the held-out official fold
%
% Training normalization is estimated ONLY from clean training data.
% Xclean and Xperturbed must be row-aligned representations of the same
% physical clips.
%
% The function is provided now as infrastructure. It does not generate the
% perturbations; future noise/reverb/channel experiment runners should do
% that once per waveform, then extract both representations from that same
% perturbed waveform.

C=config();

if nargin<8 || isempty(clipID)
    clipID="row_"+string((1:size(Xclean,1))');
else
    clipID=string(clipID(:));
end

assert(isequal(size(Xclean),size(Xperturbed)), ...
    "Clean and perturbed feature matrices must have the same size.");
assert(size(Xclean,1)==numel(Y) && numel(Y)==numel(folds), ...
    "X, Y and folds must contain the same number of observations.");
assert(numel(clipID)==numel(Y), ...
    "clipID must contain one identifier per observation.");
assert(C.robustness.trainOnCleanOnly, ...
    "Robustness configuration requires clean-only training.");

classOrder=categories(Y);
nClasses=numel(classOrder);

Fold=(1:10)';
Accuracy=zeros(10,1);
MacroF1=zeros(10,1);
PerClassRecall=zeros(10,nClasses);
PerClassF1=zeros(10,nClasses);
AggregateConfusion=zeros(nClasses,nClasses);

allClipID=strings(0,1);
allTrue=strings(0,1);
allPred=strings(0,1);
allCorrect=false(0,1);
allFold=zeros(0,1);

for f=1:10
    idxTest=folds==f;
    idxTrain=~idxTest;

    % Critical controlled design: CLEAN TRAIN / PERTURBED TEST.
    Xtr=double(Xclean(idxTrain,:));
    Xte=double(Xperturbed(idxTest,:));
    Ytr=Y(idxTrain);
    Yte=Y(idxTest);

    % Normalization statistics are fit to clean training data only.
    mu=mean(Xtr,1);
    sigma=std(Xtr,0,1);
    sigma(sigma<1e-12)=1;
    Xtr=(Xtr-mu)./sigma;
    Xte=(Xte-mu)./sigma;

    learner=templateSVM( ...
        "KernelFunction",C.svm.kernel, ...
        "BoxConstraint",C.svm.boxConstraint, ...
        "Standardize",false);

    model=fitcecoc(Xtr,Ytr, ...
        "Learners",learner, ...
        "Coding",C.svm.coding);

    yPred=predict(model,Xte);
    M=evaluate_predictions(Yte,yPred,classOrder);

    Accuracy(f)=M.accuracy;
    MacroF1(f)=M.macroF1;
    PerClassRecall(f,:)=M.recall(:)';
    PerClassF1(f,:)=M.f1(:)';
    AggregateConfusion=AggregateConfusion+M.confusion;

    currentTrue=string(Yte);
    currentPred=string(yPred);
    allClipID=[allClipID;clipID(idxTest)]; %#ok<AGROW>
    allTrue=[allTrue;currentTrue]; %#ok<AGROW>
    allPred=[allPred;currentPred]; %#ok<AGROW>
    allCorrect=[allCorrect;currentTrue==currentPred]; %#ok<AGROW>
    allFold=[allFold;repmat(f,nnz(idxTest),1)]; %#ok<AGROW>
end

FoldMetrics=table(Fold,Accuracy,MacroF1);
Summary=table(string(methodName),string(conditionName), ...
    mean(Accuracy),std(Accuracy),mean(MacroF1),std(MacroF1), ...
    'VariableNames',{'Method','Condition','MeanAccuracy','StdAccuracy', ...
    'MeanMacroF1','StdMacroF1'});

ClassMetrics=table(string(classOrder), ...
    mean(PerClassRecall,1)',std(PerClassRecall,0,1)', ...
    mean(PerClassF1,1)',std(PerClassF1,0,1)', ...
    'VariableNames',{'Class','MeanRecall','StdRecall','MeanF1','StdF1'});

Predictions=table(allClipID,allFold,allTrue,allPred,allCorrect, ...
    repmat(string(conditionName),numel(allFold),1), ...
    'VariableNames',{'ClipID','Fold','TrueLabel','PredictedLabel','Correct','Condition'});

R.method=string(methodName);
R.condition=string(conditionName);
R.foldMetrics=FoldMetrics;
R.summary=Summary;
R.classMetrics=ClassMetrics;
R.aggregateConfusion=AggregateConfusion;
R.classOrder=classOrder;
R.predictions=Predictions;

% Save in a separate robustness folder so future results stay logically
% separated from the clean benchmark.
conditionTag=regexprep(lower(string(conditionName)),"[^a-z0-9]+","_");
methodTag=regexprep(lower(string(methodName)),"[^a-z0-9]+","_");
outDir=fullfile(P.robustnessDir,conditionTag);
if ~isfolder(outDir)
    mkdir(outDir);
end
writetable(FoldMetrics,fullfile(outDir,methodTag+"_fold_metrics.csv"));
writetable(Summary,fullfile(outDir,methodTag+"_summary.csv"));
writetable(ClassMetrics,fullfile(outDir,methodTag+"_per_class_metrics.csv"));
writetable(Predictions,fullfile(outDir,methodTag+"_heldout_predictions.csv"));
end
