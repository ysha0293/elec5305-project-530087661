function R = run_official_10fold_svm(X,Y,folds,methodName,P)
%RUN_OFFICIAL_10FOLD_SVM Official UrbanSound8K 10-fold evaluation.
%
% Each official fold is used once as the held-out test fold.
% Feature normalization statistics are calculated from the nine training
% folds only, avoiding test-data leakage.

C=config();
classOrder=categories(Y);
nClasses=numel(classOrder);

Fold=(1:10)';
Accuracy=zeros(10,1);
MacroF1=zeros(10,1);
PerClassRecall=zeros(10,nClasses);
PerClassF1=zeros(10,nClasses);
AggregateConfusion=zeros(nClasses,nClasses);

allTrue=strings(0,1);
allPred=strings(0,1);
allFold=zeros(0,1);

for f=1:10

    fprintf("\n[%s] Official fold %d/10\n",methodName,f);

    idxTest=folds==f;
    idxTrain=~idxTest;

    Xtr=double(X(idxTrain,:));
    Xte=double(X(idxTest,:));
    Ytr=Y(idxTrain);
    Yte=Y(idxTest);

    %% Training-only normalization
    mu=mean(Xtr,1);
    sigma=std(Xtr,0,1);
    sigma(sigma<1e-12)=1;

    Xtr=(Xtr-mu)./sigma;
    Xte=(Xte-mu)./sigma;

    %% Simple common downstream classifier
    learner=templateSVM( ...
        "KernelFunction",C.svm.kernel, ...
        "BoxConstraint",C.svm.boxConstraint, ...
        "Standardize",false);

    model=fitcecoc( ...
        Xtr,Ytr, ...
        "Learners",learner, ...
        "Coding","onevsone");

    yPred=predict(model,Xte);

    %% Evaluation
    M=evaluate_predictions(Yte,yPred,classOrder);

    Accuracy(f)=M.accuracy;
    MacroF1(f)=M.macroF1;
    PerClassRecall(f,:)=M.recall(:)';
    PerClassF1(f,:)=M.f1(:)';
    AggregateConfusion=AggregateConfusion+M.confusion;

    allTrue=[allTrue;string(Yte)];
    allPred=[allPred;string(yPred)];
    allFold=[allFold;repmat(f,nnz(idxTest),1)];

    fprintf("Accuracy : %.2f %%\n",100*M.accuracy);
    fprintf("Macro-F1: %.4f\n",M.macroF1);

    %% Save fold confusion data
    foldConf=array2table(M.confusion, ...
        "VariableNames",matlab.lang.makeValidName(classOrder), ...
        "RowNames",classOrder);

    writetable(foldConf, ...
        fullfile(P.tableDir,sprintf("%s_fold%02d_confusion.csv", ...
        lower(methodName),f)), ...
        "WriteRowNames",true);

    plot_confusion_matrix( ...
        M.confusion,classOrder, ...
        sprintf("%s - Fold %d Confusion Matrix",methodName,f), ...
        fullfile(P.figureDir,sprintf("%s_fold%02d_confusion.png", ...
        lower(methodName),f)));
end

%% Fold-level metrics
FoldMetrics=table(Fold,Accuracy,MacroF1);
writetable(FoldMetrics, ...
    fullfile(P.tableDir,lower(methodName)+"_fold_metrics.csv"));

%% Mean +/- standard deviation
Summary=table( ...
    string(methodName), ...
    mean(Accuracy),std(Accuracy), ...
    mean(MacroF1),std(MacroF1), ...
    'VariableNames',{'Method', ...
    'MeanAccuracy','StdAccuracy', ...
    'MeanMacroF1','StdMacroF1'});

writetable(Summary, ...
    fullfile(P.tableDir,lower(methodName)+"_summary.csv"));

%% Per-class statistics across folds
MeanRecall=mean(PerClassRecall,1)';
StdRecall=std(PerClassRecall,0,1)';
MeanF1=mean(PerClassF1,1)';
StdF1=std(PerClassF1,0,1)';

ClassMetrics=table( ...
    string(classOrder),MeanRecall,StdRecall,MeanF1,StdF1, ...
    'VariableNames',{'Class','MeanRecall','StdRecall','MeanF1','StdF1'});

writetable(ClassMetrics, ...
    fullfile(P.tableDir,lower(methodName)+"_per_class_metrics.csv"));

%% Aggregate out-of-fold confusion matrix
AggTable=array2table(AggregateConfusion, ...
    "VariableNames",matlab.lang.makeValidName(classOrder), ...
    "RowNames",classOrder);

writetable(AggTable, ...
    fullfile(P.tableDir,lower(methodName)+"_aggregate_confusion.csv"), ...
    "WriteRowNames",true);

plot_confusion_matrix( ...
    AggregateConfusion,classOrder, ...
    methodName+" - Aggregate Out-of-Fold Confusion Matrix", ...
    fullfile(P.figureDir,lower(methodName)+"_aggregate_confusion.png"));

%% Save every held-out prediction
Predictions=table(allFold,allTrue,allPred, ...
    'VariableNames',{'Fold','TrueLabel','PredictedLabel'});

writetable(Predictions, ...
    fullfile(P.tableDir,lower(methodName)+"_heldout_predictions.csv"));

%% Per-method figures
plot_method_results(methodName,FoldMetrics,ClassMetrics,P);

%% Return
R.method=string(methodName);
R.foldMetrics=FoldMetrics;
R.summary=Summary;
R.classMetrics=ClassMetrics;
R.aggregateConfusion=AggregateConfusion;
R.classOrder=classOrder;
R.predictions=Predictions;
end
