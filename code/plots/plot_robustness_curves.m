function plot_robustness_curves(T,P,C)
%PLOT_ROBUSTNESS_CURVES Core RQ1 Macro-F1-versus-severity figures.

families=["noise","reverb","channel"];
for family=families
    switch family
        case "noise"
            labels=["Clean",string(C.noise.snrDb)+" dB"];
            sev=["clean",string(C.noise.snrDb)+"dB"];
            titleText="Background-noise robustness";
        case "reverb"
            labels=["Clean",string(C.reverb.rt60Seconds)+" s"];
            sev=["clean",C.reverb.labels];
            titleText="Reverberation robustness";
        case "channel"
            labels=["Clean", ...
                string(C.channel.lowHz(1))+"–"+string(C.channel.highHz(1))+" Hz", ...
                string(C.channel.lowHz(2))+"–"+string(C.channel.highHz(2))+" Hz", ...
                string(C.channel.lowHz(3))+"–"+string(C.channel.highHz(3))+" Hz"];
            sev=["clean",C.channel.labels];
            titleText="Channel / bandwidth robustness";
    end

    x=0:numel(sev)-1;
    fig=figure('Visible','off'); hold on;
    for method=["MFCC","YAMNet"]
        means=zeros(size(x)); errs=zeros(size(x));
        for k=1:numel(sev)
            if k==1
                idx=T.Method==method & T.Perturbation=="clean";
            else
                idx=T.Method==method & T.Perturbation==family & T.Severity==sev(k);
            end
            assert(nnz(idx)==1,"Missing robustness summary row for plot.");
            means(k)=T.MeanMacroF1(idx); errs(k)=T.StdMacroF1(idx);
        end
        errorbar(x,means,errs,"-o","LineWidth",1.3,"DisplayName",method+" + SVM");
    end
    xticks(x); xticklabels(labels);
    xlabel("Perturbation severity"); ylabel("Macro-F1");
    title(titleText+" (mean ± SD across official folds)");
    legend("Location","best"); ylim([0 1]); grid on;
    exportgraphics(fig,fullfile(P.figureDir,"robustness_"+family+"_macro_f1.png"),"Resolution",220);
    close(fig);
end
end
