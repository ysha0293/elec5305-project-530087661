function T = create_confusion_and_signal_analysis(noiseResults,reverbResults,channelResults,P,C)
%CREATE_CONFUSION_AND_SIGNAL_ANALYSIS Turn confusion matrices into diagnostics.
%
% For the strongest severity in each family and each representation, find
% the off-diagonal confusion whose count increased most relative to clean.
% Then select a deterministic example clip that was clean-correct but is
% perturbed into that target class, and save signal/time-frequency figures.

cleanFile=P.cleanWorkFile;
if ~isfile(cleanFile)
    legacy=fullfile(P.resultsRoot,"clean_results.mat");
    assert(isfile(legacy),"Clean reference results not found.");
    cleanFile=legacy;
end
S=load(cleanFile,"cleanResults");
clean=S.cleanResults;
meta=load_urbansound8k_metadata(P);
families={noiseResults,reverbResults,channelResults};
rows=table();

for fi=1:numel(families)
    FR=families{fi};
    if isempty(FR), continue; end
    one=FR.conditions{end}; % strongest pre-registered severity
    for method=["MFCC","YAMNet"]
        cleanR=clean.(method); pertR=one.(method);
        delta=pertR.aggregateConfusion-cleanR.aggregateConfusion;
        delta(1:size(delta,1)+1:end)=-Inf;
        [maxIncrease,linearIdx]=max(delta(:));
        [r,c]=ind2sub(size(delta),linearIdx);
        trueClass=string(pertR.classOrder{r});
        predClass=string(pertR.classOrder{c});

        % Save only the strongest pre-registered condition confusion matrix
        % for scientific discussion; do not save every condition matrix.
        confFile=fullfile(P.figureDir,"confusion_"+lower(string(FR.family))+"_strong_"+lower(method)+".png");
        plot_confusion_matrix(pertR.aggregateConfusion,pertR.classOrder, ...
            method+" - "+FR.family+" ("+one.severity+")",confFile);

        clip="";
        if isfinite(maxIncrease) && maxIncrease>0
            CP=cleanR.predictions; PP=pertR.predictions;
            [common,ia,ib]=intersect(string(CP.ClipID),string(PP.ClipID),'stable');
            cp=CP(ia,:); pp=PP(ib,:);
            mask=string(cp.TrueLabel)==trueClass & cp.Correct & ...
                string(pp.PredictedLabel)==predClass;
            candidates=sort(common(mask));
            if ~isempty(candidates)
                clip=candidates(1);
            end
        end

        row=table(method,string(FR.family),string(one.severity),trueClass,predClass, ...
            double(maxIncrease),clip, ...
            'VariableNames',{'Method','Perturbation','Severity','TrueClass','PerturbedPredictedClass','ConfusionCountIncrease','ExampleClipID'});
        if isempty(rows)
            rows=row;
        else
            rows=[rows;row]; %#ok<AGROW>
        end

        if strlength(clip)>0
            idx=find(string(meta.slice_file_name)==clip,1);
            [xClean,xPert,~,~]=generate_perturbed_waveform(meta,idx,FR.family,numel(FR.conditions),P);
            outFile=fullfile(P.figureDir,"signal_example_"+lower(string(FR.family))+"_"+lower(method)+".png");
            plot_signal_comparison(xClean,xPert,C.targetFs, ...
                sprintf('%s | %s | %s -> %s | %s',method,FR.family,trueClass,predClass,clip),outFile,C);
        end
    end
end

T=rows;
writetable(T,fullfile(P.tableDir,"confusion_change_summary.csv"));
end
