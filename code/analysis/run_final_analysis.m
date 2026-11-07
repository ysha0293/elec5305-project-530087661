function A = run_final_analysis(noiseResults,reverbResults,channelResults)
%RUN_FINAL_ANALYSIS Combine all conditions and create report-ready outputs.
%
% Only compact, report-relevant summaries are written to results/. Full
% clip-level representation distances remain in memory unless explicitly
% enabled in config.m.

P=project_paths(); C=config();
families={noiseResults,reverbResults,channelResults};

%% Clean references
cleanMFCC=readtable(fullfile(P.tableDir,"mfcc_summary.csv"));
cleanYAM=readtable(fullfile(P.tableDir,"yamnet_summary.csv"));
cleanClassMFCC=readtable(fullfile(P.tableDir,"mfcc_per_class_metrics.csv"));
cleanClassYAM=readtable(fullfile(P.tableDir,"yamnet_per_class_metrics.csv"));

robustnessSummary=table(["MFCC";"YAMNet"],["clean";"clean"],["clean";"clean"], ...
    [cleanMFCC.MeanAccuracy;cleanYAM.MeanAccuracy],[cleanMFCC.StdAccuracy;cleanYAM.StdAccuracy], ...
    [cleanMFCC.MeanMacroF1;cleanYAM.MeanMacroF1],[cleanMFCC.StdMacroF1;cleanYAM.StdMacroF1], ...
    [0;0],[0;0],'VariableNames',{'Method','Perturbation','Severity','MeanAccuracy','StdAccuracy', ...
    'MeanMacroF1','StdMacroF1','AccuracyDrop','MacroF1Drop'});

allShift=table(); classRows=table(); foldRows=table();

for fi=1:numel(families)
    FR=families{fi}; if isempty(FR), continue; end
    for ci=1:numel(FR.conditions)
        one=FR.conditions{ci};
        for method=["MFCC","YAMNet"]
            R=one.(method); S=R.summary;
            if method=="MFCC"
                cleanAcc=cleanMFCC.MeanAccuracy; cleanF1=cleanMFCC.MeanMacroF1;
                cleanClass=cleanClassMFCC; Tshift=one.shiftMFCC;
            else
                cleanAcc=cleanYAM.MeanAccuracy; cleanF1=cleanYAM.MeanMacroF1;
                cleanClass=cleanClassYAM; Tshift=one.shiftYAMNet;
            end

            robustnessSummary=[robustnessSummary; table(method,string(S.Perturbation),string(S.Severity), ...
                S.MeanAccuracy,S.StdAccuracy,S.MeanMacroF1,S.StdMacroF1, ...
                cleanAcc-S.MeanAccuracy,cleanF1-S.MeanMacroF1, ...
                'VariableNames',robustnessSummary.Properties.VariableNames)]; %#ok<AGROW>

            F=R.foldMetrics; nF=height(F);
            Frows=table(repmat(method,nF,1),repmat(string(S.Perturbation),nF,1), ...
                repmat(string(S.Severity),nF,1),F.Fold,F.Accuracy,F.MacroF1, ...
                'VariableNames',{'Method','Perturbation','Severity','Fold','Accuracy','MacroF1'});
            if isempty(foldRows), foldRows=Frows; else, foldRows=[foldRows;Frows]; end %#ok<AGROW>

            CM=R.classMetrics;
            [tf,loc]=ismember(string(CM.Class),string(cleanClass.Class));
            assert(all(tf),"Class mismatch between clean and perturbed metrics.");
            n=height(CM);
            rows=table(repmat(method,n,1),repmat(string(S.Perturbation),n,1), ...
                repmat(string(S.Severity),n,1),string(CM.Class),cleanClass.MeanRecall(loc),CM.MeanRecall, ...
                cleanClass.MeanRecall(loc)-CM.MeanRecall,cleanClass.MeanF1(loc),CM.MeanF1, ...
                cleanClass.MeanF1(loc)-CM.MeanF1, ...
                'VariableNames',{'Method','Perturbation','Severity','Class','CleanRecall', ...
                'PerturbedRecall','RecallDrop','CleanF1','PerturbedF1','ClassF1Drop'});
            if isempty(classRows), classRows=rows; else, classRows=[classRows;rows]; end %#ok<AGROW>
            if isempty(allShift), allShift=Tshift; else, allShift=[allShift;Tshift]; end %#ok<AGROW>
        end
    end
end

writetable(robustnessSummary,fullfile(P.tableDir,"robustness_summary.csv"));
writetable(foldRows,fullfile(P.tableDir,"robustness_fold_metrics.csv"));
writetable(classRows,fullfile(P.tableDir,"class_robustness.csv"));

%% Condition-level representation shift
[G,rep,pert,sev]=findgroups(allShift.Representation,allShift.Perturbation,allShift.Severity);
meanDist=splitapply(@mean,allShift.Distance,G); stdDist=splitapply(@std,allShift.Distance,G);
nClips=splitapply(@numel,allShift.Distance,G);
shiftSummary=table(rep,pert,sev,meanDist,stdDist,nClips, ...
    'VariableNames',{'Representation','Perturbation','Severity','MeanDistance','StdDistance','NClips'});
shiftSummary.MacroF1Drop=nan(height(shiftSummary),1); shiftSummary.AccuracyDrop=nan(height(shiftSummary),1);
for i=1:height(shiftSummary)
    idx=robustnessSummary.Method==shiftSummary.Representation(i) & ...
        robustnessSummary.Perturbation==shiftSummary.Perturbation(i) & robustnessSummary.Severity==shiftSummary.Severity(i);
    assert(nnz(idx)==1,"Could not uniquely match shift to performance summary.");
    shiftSummary.MacroF1Drop(i)=robustnessSummary.MacroF1Drop(idx);
    shiftSummary.AccuracyDrop(i)=robustnessSummary.AccuracyDrop(idx);
end
writetable(shiftSummary,fullfile(P.representationDir,"condition_summary.csv"));

%% Correlation within each representation
correlationTable=table();
for method=["MFCC","YAMNet"]
    idx=shiftSummary.Representation==method; x=shiftSummary.MeanDistance(idx); y=shiftSummary.MacroF1Drop(idx);
    pearson=corr(x,y,"Type","Pearson","Rows","complete");
    spearman=corr(x,y,"Type","Spearman","Rows","complete");
    row=table(method,nnz(idx),pearson,spearman,'VariableNames',{'Representation','NConditions','PearsonR','SpearmanRho'});
    if isempty(correlationTable), correlationTable=row; else, correlationTable=[correlationTable;row]; end %#ok<AGROW>
end
writetable(correlationTable,fullfile(P.representationDir,"correlation.csv"));

%% Class-level shift vs class recall drop
[Gc,repC,pertC,sevC,classC]=findgroups(allShift.Representation,allShift.Perturbation,allShift.Severity,allShift.Class);
meanClassDist=splitapply(@mean,allShift.Distance,Gc);
classShift=table(repC,pertC,sevC,classC,meanClassDist, ...
    'VariableNames',{'Method','Perturbation','Severity','Class','MeanDistance'});
classShift.RecallDrop=nan(height(classShift),1);
for i=1:height(classShift)
    idx=classRows.Method==classShift.Method(i) & classRows.Perturbation==classShift.Perturbation(i) & ...
        classRows.Severity==classShift.Severity(i) & classRows.Class==classShift.Class(i);
    assert(nnz(idx)==1,"Could not uniquely match class shift to recall drop.");
    classShift.RecallDrop(i)=classRows.RecallDrop(idx);
end
writetable(classShift,fullfile(P.representationDir,"class_shift_vs_recall_drop.csv"));

%% Core report figures and scientific confusion analysis
plot_robustness_curves(robustnessSummary,P,C);
plot_class_recall_drop(classRows,P,C);
plot_shift_vs_performance(shiftSummary,correlationTable,P);
confusionAnalysis=create_confusion_and_signal_analysis(noiseResults,reverbResults,channelResults,P,C);

A.robustnessSummary=robustnessSummary; A.foldMetrics=foldRows; A.classRobustness=classRows;
A.shiftSummary=shiftSummary; A.correlation=correlationTable; A.classShift=classShift;
A.confusionAnalysis=confusionAnalysis;
end
