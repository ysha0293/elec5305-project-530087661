function plot_clean_comparison(mfccR,yamR,P)
%PLOT_CLEAN_COMPARISON Save all MFCC-vs-YAMNet clean comparison outputs.

%% Summary table
CleanSummary=[mfccR.summary;yamR.summary];
writetable(CleanSummary,fullfile(P.tableDir,"clean_summary.csv"));
disp(CleanSummary);

%% Fold-by-fold table
FoldComparison=table( ...
    mfccR.foldMetrics.Fold, ...
    mfccR.foldMetrics.Accuracy, ...
    mfccR.foldMetrics.MacroF1, ...
    yamR.foldMetrics.Accuracy, ...
    yamR.foldMetrics.MacroF1, ...
    'VariableNames',{'Fold', ...
    'MFCC_Accuracy','MFCC_MacroF1', ...
    'YAMNet_Accuracy','YAMNet_MacroF1'});

writetable(FoldComparison, ...
    fullfile(P.tableDir,"clean_fold_comparison.csv"));

%% Accuracy mean +/- SD
accMeans=100*[mfccR.summary.MeanAccuracy;yamR.summary.MeanAccuracy];
accStd=100*[mfccR.summary.StdAccuracy;yamR.summary.StdAccuracy];

fig=figure('Visible','off');
bar(1:2,accMeans);
hold on;
errorbar(1:2,accMeans,accStd,"k.","LineWidth",1.3);
xticks(1:2);
xticklabels(["MFCC + SVM","YAMNet + SVM"]);
ylabel("Accuracy (%)");
title("Clean Accuracy: Mean ± SD across Official 10 Folds");
ylim([0 100]);
grid on;
exportgraphics(fig,fullfile(P.figureDir, ...
    "clean_accuracy_mean_std.png"),"Resolution",200);
close(fig);

%% Macro-F1 mean +/- SD
f1Means=[mfccR.summary.MeanMacroF1;yamR.summary.MeanMacroF1];
f1Std=[mfccR.summary.StdMacroF1;yamR.summary.StdMacroF1];

fig=figure('Visible','off');
bar(1:2,f1Means);
hold on;
errorbar(1:2,f1Means,f1Std,"k.","LineWidth",1.3);
xticks(1:2);
xticklabels(["MFCC + SVM","YAMNet + SVM"]);
ylabel("Macro-F1");
title("Clean Macro-F1: Mean ± SD across Official 10 Folds");
ylim([0 1]);
grid on;
exportgraphics(fig,fullfile(P.figureDir, ...
    "clean_macro_f1_mean_std.png"),"Resolution",200);
close(fig);

%% Accuracy by fold comparison
fig=figure('Visible','off');
plot(FoldComparison.Fold,100*FoldComparison.MFCC_Accuracy, ...
    "-o","LineWidth",1.3);
hold on;
plot(FoldComparison.Fold,100*FoldComparison.YAMNet_Accuracy, ...
    "-o","LineWidth",1.3);
xlabel("Official test fold");
ylabel("Accuracy (%)");
title("Clean Accuracy across Official 10 Folds");
legend("MFCC + SVM","YAMNet + SVM","Location","best");
ylim([0 100]);
xticks(1:10);
grid on;
exportgraphics(fig,fullfile(P.figureDir, ...
    "clean_accuracy_fold_comparison.png"),"Resolution",200);
close(fig);

%% Macro-F1 by fold comparison
fig=figure('Visible','off');
plot(FoldComparison.Fold,FoldComparison.MFCC_MacroF1, ...
    "-o","LineWidth",1.3);
hold on;
plot(FoldComparison.Fold,FoldComparison.YAMNet_MacroF1, ...
    "-o","LineWidth",1.3);
xlabel("Official test fold");
ylabel("Macro-F1");
title("Clean Macro-F1 across Official 10 Folds");
legend("MFCC + SVM","YAMNet + SVM","Location","best");
ylim([0 1]);
xticks(1:10);
grid on;
exportgraphics(fig,fullfile(P.figureDir, ...
    "clean_macro_f1_fold_comparison.png"),"Resolution",200);
close(fig);

%% Per-class recall comparison
ClassRecall=table( ...
    mfccR.classMetrics.Class, ...
    mfccR.classMetrics.MeanRecall, ...
    yamR.classMetrics.MeanRecall, ...
    'VariableNames',{'Class','MFCC_MeanRecall','YAMNet_MeanRecall'});

writetable(ClassRecall, ...
    fullfile(P.tableDir,"clean_per_class_recall_comparison.csv"));

fig=figure('Visible','off');
vals=100*[ ...
    mfccR.classMetrics.MeanRecall, ...
    yamR.classMetrics.MeanRecall];

bar(categorical(ClassRecall.Class),vals);
ylabel("Mean recall (%)");
title("Clean Per-Class Recall Comparison");
legend("MFCC + SVM","YAMNet + SVM","Location","best");
ylim([0 100]);
grid on;
xtickangle(35);
exportgraphics(fig,fullfile(P.figureDir, ...
    "clean_per_class_recall_comparison.png"),"Resolution",200);
close(fig);
end
