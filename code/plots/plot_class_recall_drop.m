function plot_class_recall_drop(T,P,C)
%PLOT_CLASS_RECALL_DROP Per-class failure at the strongest planned severity.

families=["noise","reverb","channel"];
strongSev=[string(C.noise.snrDb(end))+"dB",C.reverb.labels(end),C.channel.labels(end)];
for j=1:numel(families)
    family=families(j); severity=strongSev(j);
    A=T(T.Perturbation==family & T.Severity==severity,:);
    classes=unique(A.Class,'stable');
    vals=nan(numel(classes),2);
    for c=1:numel(classes)
        for m=1:2
            methods=["MFCC","YAMNet"];
            idx=A.Class==classes(c) & A.Method==methods(m);
            assert(nnz(idx)==1,"Missing class robustness row.");
            vals(c,m)=100*A.RecallDrop(idx);
        end
    end
    fig=figure('Visible','off');
    bar(categorical(classes),vals);
    ylabel("Recall drop (percentage points)");
    title("Class sensitivity: "+family+" / "+severity);
    legend("MFCC + SVM","YAMNet + SVM","Location","best");
    grid on; xtickangle(35);
    exportgraphics(fig,fullfile(P.figureDir,"class_recall_drop_"+family+"_strong.png"),"Resolution",220);
    close(fig);
end
end
