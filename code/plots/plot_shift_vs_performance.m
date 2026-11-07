function plot_shift_vs_performance(T,Corr,P)
%PLOT_SHIFT_VS_PERFORMANCE RQ2 scatter plots, one metric scale per representation.

for method=["MFCC","YAMNet"]
    A=T(T.Representation==method,:);
    c=Corr(Corr.Representation==method,:);
    fig=figure('Visible','off');
    scatter(A.MeanDistance,A.MacroF1Drop,60,'filled');
    hold on;
    if height(A)>=2
        p=polyfit(A.MeanDistance,A.MacroF1Drop,1);
        xx=linspace(min(A.MeanDistance),max(A.MeanDistance),100);
        plot(xx,polyval(p,xx),"--","LineWidth",1.2);
    end
    for i=1:height(A)
        text(A.MeanDistance(i),A.MacroF1Drop(i), ...
            "  "+A.Perturbation(i)+"/"+A.Severity(i),"FontSize",8);
    end
    xlabel("Mean clean-to-perturbed representation distance");
    ylabel("Macro-F1 drop");
    title(sprintf('%s representation shift vs performance drop (Pearson r = %.3f)',method,c.PearsonR));
    grid on;
    exportgraphics(fig,fullfile(P.figureDir,"representation_shift_vs_f1_drop_"+lower(method)+".png"),"Resolution",220);
    close(fig);
end
end
