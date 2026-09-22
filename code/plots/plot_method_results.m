function plot_method_results(methodName,FoldMetrics,ClassMetrics,P)
%PLOT_METHOD_RESULTS Save fold and class-level figures for one method.

safe=lower(methodName);

%% Accuracy across folds
fig=figure('Visible','off');
plot(FoldMetrics.Fold,100*FoldMetrics.Accuracy, ...
    "-o","LineWidth",1.3);
xlabel("Official test fold");
ylabel("Accuracy (%)");
title(methodName+" - Accuracy across Official 10 Folds");
ylim([0 100]);
xticks(1:10);
grid on;
exportgraphics(fig,fullfile(P.figureDir, ...
    safe+"_accuracy_by_fold.png"),"Resolution",200);
close(fig);

%% Macro-F1 across folds
fig=figure('Visible','off');
plot(FoldMetrics.Fold,FoldMetrics.MacroF1, ...
    "-o","LineWidth",1.3);
xlabel("Official test fold");
ylabel("Macro-F1");
title(methodName+" - Macro-F1 across Official 10 Folds");
ylim([0 1]);
xticks(1:10);
grid on;
exportgraphics(fig,fullfile(P.figureDir, ...
    safe+"_macro_f1_by_fold.png"),"Resolution",200);
close(fig);

%% Per-class recall mean +/- SD
fig=figure('Visible','off');
values=100*ClassMetrics.MeanRecall;
errors=100*ClassMetrics.StdRecall;

bar(categorical(ClassMetrics.Class),values);
hold on;
errorbar(1:height(ClassMetrics),values,errors, ...
    "k.","LineWidth",1.2);
ylabel("Recall (%)");
title(methodName+" - Per-Class Recall (Mean ± SD)");
ylim([0 100]);
grid on;
xtickangle(35);
exportgraphics(fig,fullfile(P.figureDir, ...
    safe+"_per_class_recall.png"),"Resolution",200);
close(fig);

%% Per-class F1 mean +/- SD
fig=figure('Visible','off');
values=ClassMetrics.MeanF1;
errors=ClassMetrics.StdF1;

bar(categorical(ClassMetrics.Class),values);
hold on;
errorbar(1:height(ClassMetrics),values,errors, ...
    "k.","LineWidth",1.2);
ylabel("F1-score");
title(methodName+" - Per-Class F1 (Mean ± SD)");
ylim([0 1]);
grid on;
xtickangle(35);
exportgraphics(fig,fullfile(P.figureDir, ...
    safe+"_per_class_f1.png"),"Resolution",200);
close(fig);
end
